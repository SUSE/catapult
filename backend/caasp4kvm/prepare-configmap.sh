#!/bin/bash

cluster=$(pwd | sed -e 's|/.*./||g' -e 's|-cluster||g')
IP=$(host -4 $cluster-worker1.cap.suse.de | awk '{print $NF}')
DOMAIN=$IP.$MAGICDNS

kubectl create configmap -n kube-system cap-values --from-literal=public-ip=$IP --from-literal=domain=$DOMAIN --from-literal=platform=bare
