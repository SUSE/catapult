resource "openstack_lb_listener_v2" "uaa_listener" {
  protocol        = "TCP"
  protocol_port   = "2793"
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.lb.id}"
  name            = "${var.stack_name}-uaa-listener"
}

resource "openstack_lb_pool_v2" "uaa_pool" {
  name        = "${var.stack_name}-uaa-pool"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.uaa_listener.id}"
}

resource "openstack_lb_member_v2" "uaa_member" {
  count         = "${var.workers}"
  pool_id       = "${openstack_lb_pool_v2.uaa_pool.id}"
  address       = "${element(openstack_compute_instance_v2.worker.*.access_ip_v4, count.index)}"
  subnet_id     = "${openstack_networking_subnet_v2.subnet.id}"
  protocol_port = 2793
}

resource "openstack_lb_monitor_v2" "uaa_monitor" {
  pool_id        = "${openstack_lb_pool_v2.uaa_pool.id}"
  type           = "TCP"
  url_path       = "/healthz"
  expected_codes = 200
  delay          = 10
  timeout        = 5
  max_retries    = 3
}
