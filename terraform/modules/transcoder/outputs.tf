output "hls_template_name" {
  description = "Name of HLS transcoder job template"
  value       = local.hls_template_id
}

output "mp4_template_name" {
  description = "Name of MP4 transcoder job template"
  value       = local.mp4_template_id
}
