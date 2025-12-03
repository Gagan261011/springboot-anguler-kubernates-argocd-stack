resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "join" {
  bucket = "${var.cluster_name}-join-${random_id.suffix.hex}"
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name = "${var.cluster_name}-join"
  }
}

resource "aws_s3_bucket_versioning" "join" {
  bucket = aws_s3_bucket.join.id

  versioning_configuration {
    status = "Enabled"
  }
}
