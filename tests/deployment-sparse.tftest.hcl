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
      name = "deployment-sparse"
      annotations = {
        "score.humanitec.dev/workload-type" = "Deployment"
      }
    }

    containers = {
      "main" = {
        image = "nginx:latest"
      }
    }
  }

  assert {
    condition = kubernetes_manifest.deployment[0].manifest == {
      apiVersion = "apps/v1"
      kind       = "Deployment"
      metadata = {
        name      = "deployment-sparse"
        namespace = "default"
        annotations = {
          "checksum/config" : "4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945",
          "score.humanitec.dev/workload-type" : "Deployment"
        }
        labels = {
          app = "00000000"
        }
      }
      spec = {
        selector = {
          matchLabels = {
            app = "00000000"
          }
        }
        template = {
          metadata = {
            annotations = {
              "checksum/config" : "4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945",
              "score.humanitec.dev/workload-type" : "Deployment"
            }
            labels = {
              app = "00000000"
            }
          }
          spec = {
            securityContext = {
              runAsNonRoot = true
              seccompProfile = {
                type = "RuntimeDefault"
              }
            }
            containers = [{
              name  = "main"
              image = "nginx:latest"
              securityContext = {
                allowPrivilegeEscalation = false
              }
            }]
          }
        }
      }
    }
    error_message = "manifest is not equal to ${yamlencode(kubernetes_manifest.deployment[0].manifest)}"
  }

  assert {
    condition     = length(kubernetes_service.default) == 0
    error_message = "no service should be created"
  }

  assert {
    condition     = length(kubernetes_manifest.statefulset) == 0
    error_message = "stateful set should not be set"
  }
}
