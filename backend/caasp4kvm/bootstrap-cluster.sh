#!/bin/bash

clustername=tf7-c4

rm -rf $clustername

skuba cluster init --control-plane $clustername-lb.cap.suse.de $clustername

curdir=$(pwd)
cd $clustername

skuba node bootstrap --user sles --sudo --target 10.17.2.0 $clustername-master-0

workernum="0 1"

for num in $(echo $workernum); do
    skuba node join --role worker --user sles --sudo --target 10.17.3.$num $clustername-worker-$num
done

skuba cluster status

cd $curdir
