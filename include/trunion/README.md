# Trunion #


## What is it? ##

It is a yaml merge tool: `trunion`

Trunion takes a list of dependencies and their yaml configs, a patch with
conditions and changes, and outputs a reconfigured/created values.yaml:

```
    +-------------------+
    |kubecf-values.yaml |       +-----------------+
    |                   +------>+                 |
    +-------------------+       |                 |
                                |                 |
    +-------------------+       |                 |
    |stratos-values.yaml|       |                 +------\ reconfigured/created
    |                   +------>+     Trunion     +------/   values.yaml
    +-------------------+       |                 |
                                |                 |
    +-------------------+       |                 |
    |patch file:        +------>+                 |
    |                   |       +-----------------+
    |depdendencies and  |
    |conditions         |
    |   +               |
    |yaml changes       |
    |                   |
    +-------------------+
```

Trunion patches are 2 yaml documents shipped in a file.
1. The first yaml document lists dependencies and conditions that need to be
  true to apply the changes. These are valid `jq` queries
2. The second yaml document contains the changes. It also contains possible
  operations to apply for the changes, eg:
    * `(( grab kubecf#system_domain ))` to grab the value of key `system_domain`
    from the dependency named kubecf
    * `(( grab $env_var ))` to grab the value of `$env_var`

We publish a spec for the patches, with matching json schema. Currently at `0.0.1`.


## Example of a Trunion patch ##

Let's see a patch that reconfigures the stratos config-values.yaml when our
cluster (and kubecf) is set up with LoadBalanced services.

We depend on kubecf to read from it, and stratos, to modify the already existing config.

To apply the patch, you run:
```sh
$ trunion --dependency kubecf=kubecf-config-values.yaml \
          --dependency stratos=stratos-config.yaml \
          --patch 01_stratos_service.yaml > stratos-config.yaml
```

The patch being: __01_stratos_service.yaml__
```yaml
--- # dependency constraints
spec: 0.0.1
depends_on:
- name: kubecf
  ver: "> 2.2" # metadata
  conditions:
  - ".services[] | select(.type ==  \"LoadBalancer\") | any"
apply_to: stratos

--- # patch for stratos
console:
  service:
    externalIPs: (( grab kubecf#services.router.externalIPs ))
    servicePort: 8443
services:
  loadbalanced: true
```

Note the dependency on kubecf, on the condition that there is services type
`LoadBalancer`, and how we apply the result into stratos dependency.


## Why use it? ##

The use case that kickstarted is to aid in creating a Helm distribution from
loosely coupled charts: kubecf, stratos, stratos-metrics, minibroker, etc.

As of time of writing, Helm falls short on dependency resolution, configuration
of charts on top of already configured/deployed charts that one depends on,
waiting for services of the charts to be ready, etc.

All these shortcomings could be split and attacked independently, unix style.
Trunion tries to solve the `reconfigure` step of a chart, by having a list of
optional patches to apply, depending on the present charts you depend on,
configurations, development settings, etc.
Ideally, those trunion patches would at the end be shipped with the chart.
And we hope that some similar approach would end in a helm plugin that would
allow you to do `helm fetch; helm reconfigure-for-deps; helm install` for charts
that ship those patches.

Following the approach of patches (declarative logic + changes) shipped with the
charts allows us to compute all the configurations for all the charts, taking
into account dependencies, _without the need_ to `helm install` anything. This
simplifies linting, diffing possible changes to deployments before even
deploying, testing, ownership of the changes needed for dependencies…

## Work lives in: ##

- https://github.com/SUSE/catapult/tree/v2-experiment/include/trunion
  trunion's house for now

- https://github.com/SUSE/catapult/tree/v2-experiment
  Using trunion for configuring stratos, metrics
  TODO: configure kubecf fully with trunion, and use catapult-values.yaml as dependency
