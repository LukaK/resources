module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  # allow deletion of non-empty bucket
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true

      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

}
