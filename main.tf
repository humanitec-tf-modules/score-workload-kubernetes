resource "random_id" "id" {
  byte_length = 8
}

locals {
  workload_type = lookup(coalesce(try(var.metadata.annotations, null), {}), "score.humanitec.dev/workload-type", "Deployment")
  pod_labels    = { app = random_id.id.hex }
  # Create a map of all secret data, keyed by a stable identifier
  all_secret_data = merge(
    { for k, v in kubernetes_secret.env : "env-${k}" => v.data },
    { for k, v in kubernetes_secret.files : "file-${k}" => v.data }
  )

  # Create a sorted list of the keys of the combined secret data
  sorted_secret_keys = sort(keys(local.all_secret_data))

  # Create a stable JSON string from the secret data by using the sorted keys
  stable_secret_json = jsonencode([
    for key in local.sorted_secret_keys : {
      key  = key
      data = local.all_secret_data[key]
    }
  ])

  pod_annotations = merge(
    coalesce(try(var.metadata.annotations, null), {}),
    var.additional_annotations,
    { "checksum/config" = nonsensitive(sha256(local.stable_secret_json)) }
  )

  create_service = var.service != null && length(coalesce(var.service.ports, {})) > 0

  # Flatten files from all containers into a map for easier iteration.
  # We only care about files with inline content for creating secrets.
  all_files_with_content = {
    for pair in flatten([
      for ckey, cval in var.containers : [
        for fkey, fval in coalesce(cval.files, {}) : {
          ckey      = ckey
          fkey      = fkey
          is_binary = lookup(fval, "binaryContent", null) != null
          data      = coalesce(lookup(fval, "binaryContent", null), lookup(fval, "content", null))
        } if lookup(fval, "content", null) != null || lookup(fval, "binaryContent", null) != null
      ] if cval != null
    ]) : "${pair.ckey}-${substr(sha256(pair.fkey), 0, 10)}" => pair
  }

  # Flatten all external volumes from all containers into a single map,
  # assuming volume mount paths are unique across the pod.
  all_volumes = {
    for pair in flatten([
      for ckey, cval in var.containers : [
        for vkey, vval in coalesce(cval.volumes, {}) : {
          ckey  = ckey
          vkey  = vkey
          value = vval
        }
      ] if cval != null
    ]) : "${pair.ckey}-${pair.vkey}" => pair.value
  }
}


resource "kubernetes_secret" "env" {
  for_each = nonsensitive(toset([for k, v in var.containers : k if v.variables != null]))

  metadata {
    name        = "${var.metadata.name}-${each.value}-env"
    namespace   = var.namespace
    annotations = var.additional_annotations
  }

  data = var.containers[each.value].variables
}

resource "kubernetes_secret" "files" {
  for_each = nonsensitive(toset(keys(local.all_files_with_content)))

  metadata {
    name        = "${var.metadata.name}-${each.value}"
    namespace   = var.namespace
    annotations = var.additional_annotations
  }

  data = {
    for k, v in { content = local.all_files_with_content[each.value].data } : k => v if !local.all_files_with_content[each.value].is_binary
  }

  binary_data = {
    for k, v in { content = local.all_files_with_content[each.value].data } : k => v if local.all_files_with_content[each.value].is_binary
  }
}

locals {
  manifest_metadata = {
    name        = var.metadata.name
    annotations = local.pod_annotations
    labels      = local.pod_labels
    namespace   = var.namespace
  }

  pod_template = {
    metadata = {
      annotations = local.pod_annotations
      labels      = local.pod_labels
    }
    spec = merge({
      securityContext = {
        runAsNonRoot = true
        seccompProfile = {
          type = "RuntimeDefault"
        }
      }
      containers = [for cname, container in var.containers : merge({
        name  = cname
        image = container.image
        securityContext = {
          allowPrivilegeEscalation = false
        }
        }, container.command != null ? {
        command = container.command
        } : {}, container.args != null ? {
        args = container.args
        } : {}, container.variables != null ? {
        envFrom = [{
          secretRef = {
            name = kubernetes_secret.env[cname].metadata[0].name
          }
        }]
        } : {}, container.resources != null ? {
        resources = container.resources
        } : {}, container.livenessProbe != null ? { livenessProbe = merge(
          {},
          container.livenessProbe.httpGet != null ? {
            httpGet = merge({
              port = container.livenessProbe.httpGet.port
              path = container.livenessProbe.httpGet.path
              }, container.livenessProbe.httpGet.host != null ? {
              host = container.livenessProbe.httpGet.host
              } : {}, container.livenessProbe.httpGet.scheme != null ? {
              scheme = container.livenessProbe.httpGet.scheme
              } : {}, length(coalesce(container.livenessProbe.httpGet.httpHeaders, [])) > 0 ? {
              httpHeaders = [for h in container.livenessProbe.httpGet.httpHeaders : {
                name  = h.name
                value = h.value
              }]
            } : {})
          } : {},
          container.livenessProbe.exec != null ? {
            exec = {
              command = container.livenessProbe.exec
            }
          } : {},
          ) } : {}, container.readinessProbe != null ? { readinessProbe = merge(
          {},
          container.readinessProbe.httpGet != null ? {
            httpGet = merge({
              port = container.readinessProbe.httpGet.port
              path = container.readinessProbe.httpGet.path
              }, container.readinessProbe.httpGet.host != null ? {
              host = container.readinessProbe.httpGet.host
              } : {}, container.readinessProbe.httpGet.scheme != null ? {
              scheme = container.readinessProbe.httpGet.scheme
              } : {}, length(coalesce(container.readinessProbe.httpGet.httpHeaders, [])) > 0 ? {
              httpHeaders = [for h in container.readinessProbe.httpGet.httpHeaders : {
                name  = h.name
                value = h.value
              }]
            } : {})
            } : {}, container.readinessProbe.exec != null ? {
            exec = {
              command = container.readinessProbe.exec
            }
          } : {},
        ) } : {}, try(length(container.volumes), 0) > 0 || length([for k, v in local.all_files_with_content : k if v.ckey == cname]) > 0 ? {
        volumeMounts = flatten([[for k, v in coalesce(container.volumes, {}) : {
          name      = "volume-${k}"
          mountPath = k,
          readOnly  = coalesce(v.readOnly, false)
          }], [for k, v in local.all_files_with_content : {
          name      = "file-${k}"
          mountPath = dirname(v.fkey)
          readOnly  = true
        } if v.ckey == cname]])
      } : {})]
      }, length(local.all_volumes) > 0 || length(local.all_files_with_content) > 0 ? {
      volumes = flatten([[for k, v in coalesce(local.all_volumes, {}) : {
        name = "volume-${k}"
        persistentVolumeClaim = {
          claimName = v.source
        }
        }], [for k, v in local.all_files_with_content : {
        name = "file-${k}"
        secret = {
          secretName = kubernetes_secret.files[k].metadata[0].name
          items = [{
            key  = "content"
            path = basename(v.fkey)
          }]
        }
      }]])
      } : {}, var.service_account_name != null ? {
      serviceAccountName = var.service_account_name
    } : {})
  }
}

resource "kubernetes_manifest" "deployment" {
  count = local.workload_type == "Deployment" ? 1 : 0
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata   = local.manifest_metadata
    spec = {
      selector = { matchLabels = local.pod_labels }
      template = local.pod_template
    }
  }

  wait {
    rollout = var.wait_for_rollout
  }

  timeouts {
    create = "1m"
    update = "1m"
    delete = "1m"
  }
}

resource "kubernetes_manifest" "statefulset" {
  count = local.workload_type == "StatefulSet" ? 1 : 0
  manifest = {
    apiVersion = "apps/v1"
    kind       = "StatefulSet"
    metadata   = local.manifest_metadata
    spec = {
      selector    = { matchLabels = local.pod_labels }
      serviceName = var.metadata.name
      template    = local.pod_template
    }
  }

  wait {
    rollout = var.wait_for_rollout
  }

  timeouts {
    create = "1m"
    update = "1m"
    delete = "1m"
  }
}

resource "kubernetes_service" "default" {
  count = local.create_service ? 1 : 0

  metadata {
    name        = var.metadata.name
    namespace   = var.namespace
    labels      = local.pod_labels
    annotations = var.additional_annotations
  }

  spec {
    selector = local.pod_labels

    dynamic "port" {
      for_each = coalesce(var.service.ports, {})
      iterator = service_port
      content {
        name        = service_port.key
        port        = service_port.value.port
        target_port = coalesce(service_port.value.targetPort, service_port.value.port)
        protocol    = coalesce(service_port.value.protocol, "TCP")
      }
    }
  }
}
