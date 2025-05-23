output "function_url" {
  value = google_cloudfunctions2_function.create_shard.service_config[0].uri
}
