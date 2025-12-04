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
        volumes = {
          "/special/mount" = {
            source = "some-claim"
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
    condition = kubernetes_manifest.deployment[0].manifest == {
      apiVersion = "apps/v1"
      kind       = "Deployment"
      metadata = {
        name      = "deployment-full"
        namespace = "default"
        annotations = {
          "checksum/config" : "92d8a0e916e83115d1885573f716839ba439ecdcfe124f41887d132f32d9b8d4",
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
              "checksum/config" : "92d8a0e916e83115d1885573f716839ba439ecdcfe124f41887d132f32d9b8d4",
              "score.humanitec.dev/workload-type" : "Deployment"
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
                  name = "deployment-full-main-env"
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
                name      = "volume-7f19ffb0"
                mountPath = "/special/mount"
                readOnly  = false
                }, {
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
              name = "volume-7f19ffb0"
              persistentVolumeClaim = {
                claimName = "some-claim"
              }
              }, {
              name = "file-main-eca5007265"
              secret = {
                secretName = "deployment-full-main-eca5007265"
                items = [{
                  key  = "content"
                  path = "test.txt"
                }]
              }
              }, {
              name = "file-main-f74e1bb35d"
              secret = {
                secretName = "deployment-full-main-f74e1bb35d"
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
    error_message = "manifest is not equal to ${yamlencode(kubernetes_manifest.deployment[0].manifest)}"
  }

  assert {
    condition     = kubernetes_service.default[0].metadata[0].name == "deployment-full"
    error_message = "service name should be set"
  }

  assert {
    condition     = length(kubernetes_manifest.statefulset) == 0
    error_message = "stateful set should not be set"
  }

  assert {
    condition     = length(kubernetes_secret.env) == 1
    error_message = "expected N env secrets got ${length(kubernetes_secret.env)}"
  }

  assert {
    condition     = kubernetes_secret.env["main"].metadata[0].name == "deployment-full-main-env"
    error_message = "secret env name was wrong, got ${kubernetes_secret.env["main"].metadata[0].name}"
  }

  assert {
    condition = jsonencode(kubernetes_secret.env["main"].data) == jsonencode({
      MY_ENV_VAR = "my-value"
    })
    error_message = "expected different data got ${jsonencode(nonsensitive(kubernetes_secret.env["main"].data))}"
  }

  assert {
    condition     = jsonencode(sort(keys(kubernetes_secret.files))) == jsonencode(["main-eca5007265", "main-f74e1bb35d"])
    error_message = "expected N env secrets got ${jsonencode(keys(kubernetes_secret.files))}"
  }

  assert {
    condition     = kubernetes_secret.files["main-eca5007265"].metadata[0].name == "deployment-full-main-eca5007265"
    error_message = "secret files name was wrong, got ${kubernetes_secret.files["main-eca5007265"].metadata[0].name}"
  }

  assert {
    condition = jsonencode(kubernetes_secret.files["main-eca5007265"].data) == jsonencode({
      content = "hello world"
    })
    error_message = "expected different data got ${jsonencode(nonsensitive(kubernetes_secret.files["main-eca5007265"].data))}"
  }

}
