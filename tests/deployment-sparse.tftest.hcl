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
    condition     = kubernetes_manifest.workload.manifest.metadata.name == "deployment-sparse"
    error_message = "deployment name should be set"
  }

  assert {
    condition     = length(kubernetes_service.default) == 0
    error_message = "no service should be created"
  }

  assert {
    condition     = kubernetes_manifest.workload.manifest.kind == "Deployment"
    error_message = "manifest kind should be Deployment"
  }
}
