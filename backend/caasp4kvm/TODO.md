compute1 contains terraform and skuba

ssh-agent and ssh key present

on the nfs server, create the directory

bootstrap_cluster.sh needs skuba 1.0.2, or the pattern-caasp is not installed
and it will fail

set up public ip correctly on the configmap. It uses the lb one. eg: `host tf1-c4-lb.cap.suse.de`
