mock_provider "kubernetes" {}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "00000000"
    }
  }
}

run "deployment_full" {
  command = apply

  variables {
    namespace            = "default"
    service_account_name = "something"

    metadata = {
      name = "statefulset-full"
      annotations = {
        "score.humanitec.dev/workload-type" = "StatefulSet"
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
    condition     = length(kubernetes_manifest.deployment) == 0
    error_message = "deployment name should not be set"
  }

  assert {
    condition     = kubernetes_service.default[0].metadata[0].name == "statefulset-full"
    error_message = "service name should be set"
  }

  assert {
    condition = kubernetes_manifest.statefulset[0].manifest == {
      apiVersion = "apps/v1"
      kind       = "StatefulSet"
      metadata = {
        name      = "statefulset-full"
        namespace = "default"
        annotations = {
          "checksum/config" : "92d8a0e916e83115d1885573f716839ba439ecdcfe124f41887d132f32d9b8d4",
          "score.humanitec.dev/workload-type" : "StatefulSet"
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
        serviceName = "statefulset-full"
        template = {
          metadata = {
            annotations = {
              "checksum/config" : "92d8a0e916e83115d1885573f716839ba439ecdcfe124f41887d132f32d9b8d4",
              "score.humanitec.dev/workload-type" : "StatefulSet"
            }
            labels = {
              app = "00000000"
            }
          }
          spec = {
            serviceAccountName = "something"
            securityContext = {
              runAsNonRoot = true
              seccompProfile = {
                type = "RuntimeDefault"
              }
            }
            containers = [{
              name  = "main"
              image = "nginx:latest"
              resources = {
                limits = {
                  cpu    = "200m"
                  memory = "256Mi"
                }
                requests = {
                  cpu    = "100m"
                  memory = "128Mi"
                }
              }
              securityContext = {
                allowPrivilegeEscalation = false
              }
              envFrom = [{
                secretRef = {
                  name = "statefulset-full-main-env"
                }
              }]
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
              volumeMounts = [{
                name      = "file-main-eca5007265"
                mountPath = "/mnt"
                readOnly  = true
                }, {
                name      = "file-main-f74e1bb35d"
                mountPath = "/etc"
                readOnly  = true
              }]
            }]
            volumes = [{
              name = "file-main-eca5007265"
              secret = {
                secretName = "statefulset-full-main-eca5007265"
                items = [{
                  key  = "content"
                  path = "test.txt"
                }]
              }
              }, {
              name = "file-main-f74e1bb35d"
              secret = {
                secretName = "statefulset-full-main-f74e1bb35d"
                items = [{
                  key  = "content"
                  path = "other.txt"
                }]
              }
            }]
          }
        }
      }
    }
    error_message = "manifest is not equal to ${yamlencode(kubernetes_manifest.statefulset[0].manifest)}"
  }
}
