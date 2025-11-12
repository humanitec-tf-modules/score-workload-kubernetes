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
      name = "statefulset-sparse"
      annotations = {
        "score.humanitec.dev/workload-type" = "StatefulSet"
      }
    }

    containers = {
      "main" = {
        image = "nginx:latest"
      }
    }
  }

  assert {
    condition     = length(kubernetes_deployment.default) == 0
    error_message = "deployment name should not be set"
  }

  assert {
    condition     = length(kubernetes_service.default) == 0
    error_message = "no service should be created"
  }

  assert {
    condition     = kubernetes_stateful_set.default[0].metadata[0].name == "statefulset-sparse"
    error_message = "stateful set name should be set"
  }
}
