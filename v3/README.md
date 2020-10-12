## TRACKER: Catapult v3

## Catapult as harness and test utility for helm charts & kube operations ##

A test harness/framework for a helm chart includes, in a declarative manner:
- A contained shell env for Helm, Kubectl, CF, k8s provider cli, etc. Accessible
  via .envrc
- A k8s cluster
- An optional values.yaml of the chart under test
- Executables (Testsuites, oneoffs) to run against the System Under Test (SUT:
  env, cluster, helm release)
- TODO code for helm install, upgrade, wait, config
  Picked up from the chart themselves?
- Artifacts resulting from all of the above

Declarative: Instead of options in env vars, provide
a catapult-values.yaml file that specifies the Before state of the test. That
catapult-values.yaml (or subsets of it) can be checked in into git, documenting
the different testing plans.

## One-offs ##

## Do the minimum ##

When possible, catapult tries to not implement testsuites or deployment
mechanisms, and off loads that where it corresponds (eg: deploying and waiting
for kubecf, it's taken from kubecf repo. Running cats is taken from cats or kubecf).

# Why? #

Helm charts are nice, but incomplete if one is building a "Helm chart
distribution" without using helmfiles or making a chart of charts.

Helm charts sometimes depend on each other, or need specific test harnesses.

## List of tasks ##

1. [ ] Pin Catapult on all consumers to current v2 version
  - [x] KubeCF Concourse CI
  - [ ] KubeCF GH Actions CI
  - [ ] CAP CI
  - [ ] CaaSP CI (validator)
  - [ ] caps registry CI
2. [ ] Iterate on design
3. [ ] Implement harness part of:
  - Contained shell env for Helm, Kubectl, CF, etc, accessible via .envrc.
    Track tools versions and checksums as done in scripts/kubecf
  - Declarative state of harness in a catapult-values.yaml file.
  - Validate catapult-values.yaml against schema
  - Implement k8s cluster creation
4. [ ] Consume catapult-v3 k8s cluster creation in different CIs, leave rest to
       catapult v2.
5. [ ] Iterate on design and implementation on helm states:
  - obtain helm chart
  - compile helm values.yaml
  - install helm release
  - upgrade helm release
  - wait for helm release to be ready
  These steps may be implemented in scripts shipped together with the helm chart.
6. [ ] Iterate on design and implementation of testsuite targets, and one-offs
7. [ ] Consume catapult-v3 k8s fully in different CIs


## Usage ##

```bash

$ ctp --config=catapult-values.yaml caasp
$ ctp --config=catapult-values.yaml kubecf --values=examples/kubecf/diego-values.yaml

$ ctp --config=catapult-values.yaml kubecf-clean --values=examples/kubecf/diego-values.yaml
```


```
$ ctp -c catapult-values.yaml kubecf -v examples/kubecf/diego-values.yaml
```


```
$ ctp kubecf -v examples/kubecf/diego-values.yaml
```

```
$ ctp kind kubecf
```

```
$ ctp <tab>
```

## catapult config values ##

```
$ ctp val magicdns
omg.howdoi.website

$ ctp val backend.gke.node_count
3
```

