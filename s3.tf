resource "aws_s3_bucket" "frontend" {
  bucket        = "flashcardify-frontend-${terraform.workspace}"
  force_destroy = true
  acl           = "public-read"
  policy        = "${data.aws_iam_policy_document.static_website.json}"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
