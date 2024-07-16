output "bucket_name" {
  description = "Name of the bucket"
  value       = module.bucket.s3_bucket_id
}
