# score-workload-kubernetes

This is a Terraform / OpenTofu compatible module to be used to provision `score-workload` resources ontop of Kubernetes for the Humanitec Orchestrator.

## Requirements

1. There must be a module provider setup for `kubernetes` (`hashicorp/kubernetes`).
2. There must be a resource type setup for `score-workload`, for example:

    ```
    hctl create resource-type score-workload --set=description='Score Workload' --set=output_schema='{"type":"object","properties":{"endpoint":{"type":"string","description":"An optional endpoint uri that the workload's service ports will be exposed on if any are defined"}}}'
    ```

## Installation

Install this with the `hctl` CLI, you should replace the `CHANGEME` in the module source with the latest release tag, replace the `CHANGEME` in the provider mapping with your real provider type and alias for Kubernetes; and replace the `CHANGEME` in module inputs with the real target namespace.

```shell
hctl create module \
    --set=resource_type=score-workload \
    --set=module_source=git::https://github.com/humanitec-tf-mofules/score-workload-kubernetes?ref=CHANGEME \
    --set=provider_mapping='{"kubernetes": "CHANGEME"}' \
    --set=module_inputs='{"namespace": "CHANGEME"}'
```

## Resource Outputs

The following outputs are exposed

| Name            | Description                                             | Type     |
| --------------- | ------------------------------------------------------- | -------- |
| `endpoint`      | The dns name of the clusterip service for this workload | `string` |

## Module Inputs

The following input variables can be set in the `module_inputs` of the `hctl create module` command.

| Name                     | Description                                           | Type       | Default | Required |
| ------------------------ | ----------------------------------------------------- | ---------- | ------- | -------- |
| `namespace`              | The namespace to deploy to.                           | `string`   |         | yes      |
| `service_account_name`   | The name of the service account to use for the pods.  | `string`   | `null`  | no       |
| `additional_annotations` | Additional annotations to add to all resources.       | `map(string)` | `{}`    | no       |
| `wait_for_rollout`       | Whether to wait for the workload to be rolled out.    | `bool`     | `true`  | no       |

For example, to set the `service_account_name` and disable `wait_for_rollout`, you would use:

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
