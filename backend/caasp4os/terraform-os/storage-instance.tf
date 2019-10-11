# NFS storage addon receipt for caasp4 terraform based deployments
#
# Copy this file to ~/caasp/deployment/openstack/ on your caasp management
# system before running 
#   `terraform apply` 
# to deploy the cluster. It then will add an additional opensuse leap15.1
# machine to the caasp4 network running a nfs server, sharing 
# /srv/nfs/kubedata with the proper permissions.
# This nfs share can then be consumed by nfs provisoener within caasp4.
#
# Warning: This receipt consumes caasp4 templates and will not work outside
# the caasp4 terraform environment.


locals {
  image = "openSUSE-Leap-15.1-JeOS.x86_64-OpenStack-Cloud"
  flavor = "c4.large"
  user = "opensuse"
  nfs_config = "rw,sync,no_subtree_check,no_root_squash,no_all_squash,insecure"
  nfs_share = "/srv/nfs/kubedata"
  storage_packages = [
    "kernel-default",
    "-kernel-default-base",
    "nfs-client",
    "nfs-kernel-server",
    "yast2-nfs-server"
  ]
}

data "template_file" "storage_repositories" {
  template = "${file("cloud-init/repository.tpl")}"
  count    = "${length(var.repositories)}"

  vars {
    repository_url  = "${element(values(var.repositories), count.index)}"
    repository_name = "${element(keys(var.repositories), count.index)}"
  }
}

data "template_file" "storage_register_scc" {
  template = "${file("cloud-init/register-scc.tpl")}"
  count    = "${var.caasp_registry_code == "" ? 0 : 1}"

  vars {
    caasp_registry_code = "${var.caasp_registry_code}"
  }
}

data "template_file" "storage_register_rmt" {
  template = "${file("cloud-init/register-rmt.tpl")}"
  count    = "${var.rmt_server_name == "" ? 0 : 1}"

  vars {
    rmt_server_name = "${var.rmt_server_name}"
  }
}

data "template_file" "storage_commands" {
  template = "${file("cloud-init/commands.tpl")}"

  vars {
    packages = "${join(", ", local.storage_packages)}"
  }
}

data "template_file" "storage-cloud-init" {
  template = "${file("cloud-init/common.tpl")}"

  vars {
    authorized_keys = "${join("\n", formatlist("  - %s", var.authorized_keys))}"
    repositories    = ""
    register_scc    = ""
    register_rmt    = ""
    commands        = "${join("\n", data.template_file.storage_commands.*.rendered)}"
    username        = "${local.user}" 
    ntp_servers     = "${join("\n", formatlist ("    - %s", var.ntp_servers))}"
  }
}

resource "openstack_compute_instance_v2" "storage" {
  count      = 1
  name       = "caasp-storage-${var.stack_name}-${count.index}"
  image_name = "${local.image}"

  depends_on = [
    "openstack_networking_network_v2.network",
    "openstack_networking_subnet_v2.subnet",
  ]

  flavor_name = "${local.flavor}"

  network {
    name = "${var.internal_net}"
  }

  security_groups = [
    "${openstack_compute_secgroup_v2.storage.name}",
    "${openstack_networking_secgroup_v2.common.name}",
  ]

  user_data = "${data.template_file.storage-cloud-init.rendered}"
}

resource "openstack_networking_floatingip_v2" "storage_ext" {
  count = 1
  pool  = "${var.external_net}"
}

resource "openstack_compute_floatingip_associate_v2" "storage_ext_ip" {
  count       = 1 
  floating_ip = "${element(openstack_networking_floatingip_v2.storage_ext.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.storage.*.id, count.index)}"
}

resource "null_resource" "storage_wait_cloudinit" {
  depends_on = ["openstack_compute_instance_v2.storage"]
  count      = 1

  connection {
    host = "${element(openstack_compute_floatingip_associate_v2.storage_ext_ip.*.floating_ip, count.index)}"
    user = "${local.user}"
    type = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait > /dev/null",
    ]
  }
}

resource "null_resource" "storage_reboot" {
  depends_on = ["null_resource.storage_config"]
  count      = 1

  provisioner "local-exec" {
    environment = {
      user = "${local.user}"
      host = "${element(openstack_compute_floatingip_associate_v2.storage_ext_ip.*.floating_ip, count.index)}"
    }

    command = <<EOT
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host sudo reboot || :
# wait for ssh ready after reboot
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -oConnectionAttempts=60 $user@$host /usr/bin/true
EOT
  }
}

resource "null_resource" "storage_config" {
  depends_on = ["null_resource.storage_wait_cloudinit"]
  count      = 1

  connection {
    host = "${element(openstack_compute_floatingip_associate_v2.storage_ext_ip.*.floating_ip, count.index)}"
    user = "${local.user}"
    type = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /srv/nfs/kubedata",
      "sudo chmod 777 /srv/nfs/kubedata",
      "sudo chown nobody: /srv/nfs/kubedata",
      "sudo yast nfs_server add mountpoint=\"${local.nfs_share}\" hosts=\"*\" options=\"${local.nfs_config}\"",
      "sudo yast nfs_server set enablev4=\"Yes\" domain=\"localdomain\" security=\"No\"",
      "sudo systemctl enable nfs-server",
    ]
  }
}

resource "openstack_compute_secgroup_v2" "storage" {
  name        = "caasp-storage-${var.stack_name}"
  description = "Basic security group"

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 111
    to_port     = 111
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 2049
    to_port     = 2049
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 20048
    to_port     = 20048
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 33904
    to_port     = 33904
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 111
    to_port     = 111
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 2049
    to_port     = 2049 
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 20048
    to_port     = 20048
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 33904 
    to_port     = 33904
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
}

output "ip_storage_ext" {
  value = "${openstack_networking_floatingip_v2.storage_ext.address}"
}

output "ip_storage_int" {
  value = "${openstack_compute_instance_v2.storage.access_ip_v4}"
}

output "storage_share" {
  value = "${local.nfs_share}"
}

