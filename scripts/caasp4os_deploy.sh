#!/usr/bin/env bash


# Deploys Caasp4 cluster on openstack, with an nfs server
# Requires:
# - Built skuba docker image
# - Sourced openrc.sh
# - Key on the ssh keyring. If not, will put one

set -exo pipefail

. scripts/include/caasp4os.sh
. scripts/include/skuba.sh
. scripts/include/common.sh
. .envrc

set -u

export STACK=${STACK:-"$(whoami)-${CAASP_VER::3}-caasp4-cf-ci"}
export DEBUG=${DEBUG:-0}
export DOMAIN=${DOMAIN:-'omg.howdoi.website'}


if [[ ! -v OS_PASSWORD ]]; then
    echo ">>> Missing openstack credentials" && exit 1
fi

# Add ssh key if not present, needed for terraform
agent="$(pgrep ssh-agent -u "$USER")"
if [[ "$agent" == "" ]]; then
    eval "$(ssh-agent -s)"
fi
if ! ssh-add -L | grep -q 'ssh' ; then
    curl "https://raw.githubusercontent.com/SUSE/skuba/master/ci/infra/id_shared" -o id_rsa \
        && chmod 0600 id_rsa_shared
    ssh-add id_rsa_shared
fi

# Extract upstream caasp terraform files
docker run \
       --name skuba-"$CAASP_VER" \
       --detach \
       --rm \
       skuba/"$CAASP_VER" sleep infinity
docker cp \
       skuba-"$CAASP_VER":/usr/share/caasp/terraform/openstack/. \
       deployment
docker rm -f skuba-"$CAASP_VER"

# Inject our terraform files
case "$CAASP_VER" in
    "devel")
         CAASP_REPO='caasp_40_devel_sle15sp1 = "http://download.suse.de/ibs/Devel:/CaaSP:/4.0/SLE_15_SP1/"'
         ;;
    "staging")
         CAASP_REPO='caasp_40_staging_sle15sp1 = "http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40/staging/"'
         ;;
    "product")
         CAASP_REPO='caasp_40_product_sle15sp1 = "http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40/standard/"'
         ;;
    "update")
         CAASP_REPO='caasp_40_update_sle15sp1 = "http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40:/Update/standard/"'
         ;;
esac
escapeSubst() {
    # escape string for usage in a sed substitution expression
    IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's%[&/\]%\\&%g; s%\n%\\&%g' <<<"$1")
    printf %s "${REPLY%$'\n'}"
}
SSHKEY="$(ssh-add -L)"
CAASP_PATTERN='patterns-caasp-Node-1.15'
sed -e "s%#~placeholder_stack~#%$(escapeSubst "$STACK")%g" \
    -e "s%#~placeholder_magic_dns~#%$(escapeSubst "$DOMAIN")%g" \
    -e "s%#~placeholder_caasp_repo~#%$(escapeSubst "$CAASP_REPO")%g" \
    -e "s%#~placeholder_sshkey~#%$(escapeSubst "$SSHKEY")%g" \
    -e "s%#~placeholder_caasp_pattern~#%$(escapeSubst "$CAASP_PATTERN")%g" \
    ../caasp4/terraform-os/terraform.tfvars.skel > \
    deployment/terraform.tfvars
sed -i '/\"\${openstack_networking_secgroup_v2\.secgroup.common\.name}\",/a \ \ \ \ "\${openstack_compute_secgroup_v2.secgroup_cap.name}",' \
    deployment/worker-instance.tf
cp -r ../caasp4/terraform-os/* deployment/

pushd deployment

# Deploy infra with terraform
skuba_container terraform init
skuba_container terraform plan -out my-plan
skuba_container terraform apply -auto-approve my-plan

# Bootstrap k8s with skuba
skuba_deploy
wait
cp -f ./my-cluster/admin.conf ../kubeconfig

# Disable annoying k8s cluster options
skuba_updates all disable
wait
skuba_reboots disable
wait

# Enable swapaccount on all k8s nodes
skuba_run_cmd all "sudo sed -i -r 's|^(GRUB_CMDLINE_LINUX_DEFAULT=)\"(.*.)\"|\1\"\2 cgroup_enable=memory swapaccount=1 \"|' /etc/default/grub"
wait
skuba_run_cmd all 'sudo grub2-mkconfig -o /boot/grub2/grub.cfg'
wait
skuba_run_cmd all 'sleep 2 && sudo nohup shutdown -r now > /dev/null 2>&1 &'
wait
# skuba_wait_ssh all 100
sleep 100

# Create k8s configmap
PUBLIC_IP="$(skuba_container terraform output ip_workers | cut -d, -f1 | head -n1)"
export PUBLIC_IP
ROOTFS=overlay-xfs
export ROOTFS
NFS_SERVER_IP="$(skuba_container terraform output ip_storage_int)"
export NFS_SERVER_IP
NFS_PATH="$(skuba_container terraform output storage_share)"
export NFS_PATH

if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=nfs-server-ip="${NFS_SERVER_IP}" \
            --from-literal=nfs-path="${NFS_PATH}" \
            --from-literal=platform=caasp4
fi
