mock_provider "kubernetes" {}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "00000000"
    }
  }
}

run "deployment_full" {
  command = plan

  variables {
    namespace = "default"

    metadata = {
      name = "deployment-full"
      annotations = {
        "score.humanitec.dev/workload-type" = "Deployment"
      }
    }

    containers = {
      "main" = {
        image = "nginx:latest"
        variables = {
          "MY_ENV_VAR" = "my-value"
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
        files = {
          "/mnt/test.txt" = {
            content = "hello world"
          }
          "/etc/other.txt" = {
            binaryContent = "Zml6emJ1enoK"
          }
        }
        livenessProbe = {
          httpGet = {
            path = "/"
            port = 80
          }
        }
        readinessProbe = {
          httpGet = {
            path = "/"
            port = 80
          }
        }
      }
    }

    service = {
      ports = {
        "http" = {
          port       = 80
          targetPort = 80
        }
      }
    }
  }

  assert {
    condition     = kubernetes_deployment.default[0].metadata[0].name == "deployment-full"
    error_message = "deployment name should be set"
  }

  assert {
    condition     = kubernetes_service.default[0].metadata[0].name == "deployment-full"
    error_message = "service name should be set"
  }

  assert {
    condition     = length(kubernetes_stateful_set.default) == 0
    error_message = "stateful set should not be set"
  }
}
