#!/usr/bin/env bash


# Deploys Caasp4 cluster on openstack, with an nfs server
# Requires:
# - Built skuba docker image
# - Sourced openrc.sh
# - Key on the ssh keyring. If not, will put one

. ./defaults.sh
. ./lib/skuba.sh
. ../../include/common.sh
. .envrc

# nip.io doesn't seem to work well with ECP, use omg.h.w instead:
export MAGICDNS=omg.howdoi.website


if [[ ! -v OS_PASSWORD ]]; then
    echo ">>> Missing openstack credentials" && exit 1
fi

# Add ssh key if not present, needed for terraform
if ! ssh-add -L | grep -q 'ssh' ; then
    if [[ $(pgrep ssh-agent -u "$USER") ]]; then
        eval "$(ssh-agent -s)"
    fi
    curl "https://raw.githubusercontent.com/SUSE/skuba/master/ci/infra/id_shared" -o id_rsa_shared \
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
         # Already on terraform.tfvars
         CAASP_REPO=
         ;;
    "update")
         CAASP_REPO='caasp_40_update_sle15sp1 = "http://download.suse.de/ibs/SUSE/Updates/SUSE-CAASP/4.0/x86_64/update/"',
         ;;
esac
escapeSubst() {
    # escape string for usage in a sed substitution expression
    IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's%[&/\]%\\&%g; s%\n%\\&%g' <<<"$1")
    printf %s "${REPLY%$'\n'}"
}
# save only first ssh key, caasp4 terraform script constraints:
SSHKEY="$(ssh-add -L | head -n 1)"
sed -e "s%#~placeholder_stack~#%$(escapeSubst "$STACK")%g" \
    -e "s%#~placeholder_magic_dns~#%$(escapeSubst "$MAGICDNS")%g" \
    -e "s%#~placeholder_caasp_repo~#%$(escapeSubst "$CAASP_REPO")%g" \
    -e "s%#~placeholder_sshkey~#%$(escapeSubst "$SSHKEY")%g" \
    "$ROOT_DIR"/backend/caasp4os/terraform-os/terraform.tfvars.skel > \
    deployment/terraform.tfvars
cp -r "$ROOT_DIR"/backend/caasp4os/terraform-os/* deployment/

pushd deployment

# Deploy infra with terraform
skuba_container terraform init
skuba_container terraform plan -out my-plan
skuba_container terraform apply -auto-approve my-plan

# Bootstrap k8s with skuba
skuba_container skuba version
skuba_deploy
wait
cp -f ./my-cluster/admin.conf ../kubeconfig

# Disable annoying k8s cluster options
skuba_updates all disable
wait
# skuba_reboots disable
# wait

# Create k8s configmap
PUBLIC_IP="$(skuba_container terraform output ip_workers | cut -d, -f1 | head -n1)"
ROOTFS=overlay-xfs
NFS_SERVER_IP="$(skuba_container terraform output ip_storage_int)"
NFS_PATH="$(skuba_container terraform output storage_share)"
DOMAIN="$PUBLIC_IP"."$MAGICDNS"

if ! kubectl get configmap -n kube-system 2>/dev/null | grep -qi cap-values; then
    kubectl create configmap -n kube-system cap-values \
            --from-literal=public-ip="${PUBLIC_IP}" \
            --from-literal=domain="${DOMAIN}" \
            --from-literal=garden-rootfs-driver="${ROOTFS}" \
            --from-literal=nfs-server-ip="${NFS_SERVER_IP}" \
            --from-literal=nfs-path="${NFS_PATH}" \
            --from-literal=platform=caasp4
fi
