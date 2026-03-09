terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    deepmerge = {
      source  = "isometry/deepmerge"
      version = ">= 0.2.0"
    }
  }
}
