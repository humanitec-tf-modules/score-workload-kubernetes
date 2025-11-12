# score-workload-kubernetes

This is a Terraform / OpenTofu compatible module to be used to provision `score-workload` resources ontop of Kubernetes for the Humanitec Orchestrator.

## Requirements

1. There must be a module provider setup for `kubernetes` (`hashicorp/kubernetes`).
2. There must be a resource type setup for `score-workload`, for example:

    ```shell
    hctl create resource-type score-workload --set=description='Score Workload' --set=output_schema='{"type":"object","properties":{"endpoint":{"type":"string","description":"An optional endpoint uri that the workload's service ports will be exposed on if any are defined"}}}'
    ```

## Installation

Install this with the `hctl` CLI, you should replace the `CHANGEME` in the module source with the latest release tag, replace the `CHANGEME` in the provider mapping with your real provider type and alias for Kubernetes; and replace the `CHANGEME` in module inputs with the real target namespace.

```shell
hctl create module \
    --set=resource_type=score-workload \
    --set=module_source=git::https://github.com/humanitec-tf-modules/score-workload-kubernetes?ref=CHANGEME \
    --set=provider_mapping='{"kubernetes": "CHANGEME"}' \
    --set=module_params='{"metadata":{"type":"map"},"containers":{"type":"map"},"service":{"type":"map","is_optional":true}}' \
    --set=module_inputs='{"namespace": "CHANGEME"}'
```

## Parameters

The module is designed to pass the `metadata`, `containers`, and `service` as parameters from the source score file, with any other module [inputs](#inputs) set by the platform engineer.

The only required input that must be set by the `module_inputs` is the `namespace` which provides the target Kubernetes namespace.

For example, to set the `namespace`, `service_account_name` and disable `wait_for_rollout`, you would use:

```shell
hctl create module \
    ...
    --set=module_inputs='{"namespace": "my-namespace", "service_account_name": "my-sa", "wait_for_rollout": false}'
```

### Dynamic namespaces

Instead of a hardcoded destination namespace, you can use the resource graph to provision a namespace.

1. Ensure there is a resource type for the namespace (eg: `k8s-namespace`) and that there is a module and rule set up for it in the target environments.
2. Add a dependency to the create module request:

    ```
    --set=dependencies='{"ns": {"type": "k8s-namespace"}}'
    ```

3. In the module inputs replace this with the placeholder:

    ```
    --set=module_inputs='{"namespace": "${ resources.ns.outputs.name }"}'
    ```

## Workload Type

By default this module produces Kubernetes Deployments. To switch to a StatefulSet, the Score workload should set the following annotation:

```yaml
metadata:
  annotations:
    score.humanitec.dev/workload-type: StatefulSet
```
