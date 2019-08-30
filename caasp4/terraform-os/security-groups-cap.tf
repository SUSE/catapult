resource "openstack_compute_secgroup_v2" "secgroup_cap" {
  name        = "caasp-cap-${var.stack_name}"
  description = "CAP security group"

  rule {
    from_port   = 80 
    to_port     = 80 
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443 
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 2222 
    to_port     = 2222
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 2793
    to_port     = 2793
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 4443 
    to_port     = 4443 
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 20000 
    to_port     = 20008 
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}
