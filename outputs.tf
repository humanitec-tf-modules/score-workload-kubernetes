output "humanitec_metadata" {
  description = "Metadata for Humanitec."
  value = merge(
    {
      "Kubernetes-Namespace" = var.namespace
    },
    local.create_service ? { "Kubernetes-Service" = kubernetes_service.default[0].metadata[0].name } : {},
    local.workload_type == "Deployment" ? { "Kubernetes-Deployment" = kubernetes_manifest.workload.manifest.metadata.name } : {},
    local.workload_type == "StatefulSet" ? { "Kubernetes-StatefulSet" = kubernetes_manifest.workload.manifest.metadata.name } : {}
  )
}

output "endpoint" {
  description = "An optional endpoint uri that the workload's service ports will be exposed on if any are defined"
  value       = local.create_service ? "${var.metadata.name}.${var.namespace}.svc.cluster.local" : null
}
