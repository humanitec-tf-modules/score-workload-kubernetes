mock_provider "kubernetes" {}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "00000000"
    }
  }
}

run "deployment_with_extensions" {
  command = plan

  variables {
    namespace = "default"

    metadata = {
      name = "deployment-ext"
      annotations = {
        "score.humanitec.dev/workload-type" = "Deployment"
      }
      "score.humanitec.dev/extension" = {
        deployment = {
          metadata = {
            annotations = {
              "my-custom-annotation" = "$${resources.db.host}"
            }
          }
          replicas = 3
          strategy = {
            type = "Recreate"
          }
        }
        pod = {
          metadata = {
            labels = {
              "my-custom-label" = "pod-label-value"
            }
          }
          initContainers = [
            {
              name    = "init-myservice"
              image   = "busybox:1.28"
              command = ["sh", "-c", "echo Hello"]
            }
          ]
        }
      }
    }

    containers = {
      "main" = {
        image = "nginx:latest"
      }
    }
  }

  assert {
    condition     = try(kubernetes_manifest.workload.manifest.spec.replicas, 0) == 3
    error_message = "spec.replicas should be patched from extension"
  }

  assert {
    condition     = try(kubernetes_manifest.workload.manifest.spec.strategy.type, "") == "Recreate"
    error_message = "spec.strategy.type should be patched from extension"
  }

  assert {
    condition     = try(kubernetes_manifest.workload.manifest.spec.template.spec.initContainers[0].name, "") == "init-myservice"
    error_message = "spec.template.spec.initContainers should be patched from extension"
  }

  assert {
    condition     = try(kubernetes_manifest.workload.manifest.metadata.annotations["my-custom-annotation"], "") == "$${resources.db.host}"
    error_message = "metadata.annotations should be patched from extension"
  }

  assert {
    condition     = try(kubernetes_manifest.workload.manifest.spec.template.metadata.labels["my-custom-label"], "") == "pod-label-value"
    error_message = "spec.template.metadata.labels should be patched from extension"
  }
}

run "statefulset_with_extensions" {
  command = plan

  variables {
    namespace = "default"

    metadata = {
      name = "statefulset-ext"
      annotations = {
        "score.humanitec.dev/workload-type" = "StatefulSet"
      }
      "score.humanitec.dev/extension" = {
        deployment = {
          metadata = {
            annotations = {
              "my-custom-annotation" = "$${resources.db.host}"
            }
          }
          replicas = 3
        }
      }
    }

    containers = {
      "main" = {
        image = "nginx:latest"
      }
    }
  }

  assert {
    condition     = try(kubernetes_manifest.workload.manifest.spec.serviceName, "") == "statefulset-ext"
    error_message = "spec.serviceName should not be clobbered by extension for StatefulSet"
  }

  assert {
    condition     = try(kubernetes_manifest.workload.manifest.metadata.annotations["my-custom-annotation"], "") == "$${resources.db.host}"
    error_message = "metadata.annotations should be patched from extension"
  }

  assert {
    condition     = try(kubernetes_manifest.workload.manifest.spec.replicas, 0) == 3
    error_message = "spec.replicas should be patched from extension"
  }
}
