# Outputs disabled - Eventarc triggers are temporarily disabled
# Uncomment after enabling the Eventarc triggers in main.tf

/*
output "video_upload_trigger_name" {
  description = "Name of the video upload Eventarc trigger (primary)"
  value       = google_eventarc_trigger.video_upload_trigger.name
}

output "video_upload_trigger_secondary_name" {
  description = "Name of the video upload Eventarc trigger (secondary)"
  value       = var.enable_secondary_region ? google_eventarc_trigger.video_upload_trigger_secondary[0].name : null
}
*/

