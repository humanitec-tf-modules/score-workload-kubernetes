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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_deployment.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_secret.env](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.files](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_stateful_set.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/stateful_set) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_annotations"></a> [additional\_annotations](#input\_additional\_annotations) | Additional annotations to add to all resources. | `map(string)` | `{}` | no |
| <a name="input_containers"></a> [containers](#input\_containers) | The containers section of the Score file. | <pre>map(object({<br/>    image     = string<br/>    command   = optional(list(string))<br/>    args      = optional(list(string))<br/>    variables = optional(map(string))<br/>    files = optional(map(object({<br/>      source        = optional(string)<br/>      content       = optional(string)<br/>      binaryContent = optional(string)<br/>      mode          = optional(string)<br/>      noExpand      = optional(bool)<br/>    })))<br/>    volumes = optional(map(object({<br/>      source   = string<br/>      path     = optional(string)<br/>      readOnly = optional(bool)<br/>    })))<br/>    resources = optional(object({<br/>      limits = optional(object({<br/>        memory = optional(string)<br/>        cpu    = optional(string)<br/>      }))<br/>      requests = optional(object({<br/>        memory = optional(string)<br/>        cpu    = optional(string)<br/>      }))<br/>    }))<br/>    livenessProbe = optional(object({<br/>      httpGet = optional(object({<br/>        host   = optional(string)<br/>        scheme = optional(string)<br/>        path   = string<br/>        port   = number<br/>        httpHeaders = optional(list(object({<br/>          name  = string<br/>          value = string<br/>        })))<br/>      }))<br/>      exec = optional(object({<br/>        command = list(string)<br/>      }))<br/>    }))<br/>    readinessProbe = optional(object({<br/>      httpGet = optional(object({<br/>        host   = optional(string)<br/>        scheme = optional(string)<br/>        path   = string<br/>        port   = number<br/>        httpHeaders = optional(list(object({<br/>          name  = string<br/>          value = string<br/>        })))<br/>      }))<br/>      exec = optional(object({<br/>        command = list(string)<br/>      }))<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | The metadata section of the Score file. | `any` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace to deploy the resources into. | `string` | n/a | yes |
| <a name="input_service"></a> [service](#input\_service) | The service section of the Score file. | <pre>object({<br/>    ports = optional(map(object({<br/>      port       = number<br/>      protocol   = optional(string)<br/>      targetPort = optional(number)<br/>    })))<br/>  })</pre> | `null` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | The name of the service account to use for the pods. | `string` | `null` | no |
| <a name="input_wait_for_rollout"></a> [wait\_for\_rollout](#input\_wait\_for\_rollout) | Whether to wait for the workload to be rolled out. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | An optional endpoint uri that the workload's service ports will be exposed on if any are defined |
| <a name="output_humanitec_metadata"></a> [humanitec\_metadata](#output\_humanitec\_metadata) | Metadata for Humanitec. |
<!-- END_TF_DOCS -->