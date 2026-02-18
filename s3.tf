# ==========================================================
# S3 (Optional)
# Purpose in this project:
# - Keep a copy of your static site artifacts (index.html, style.css) in S3
# - Bucket is private by design (no public website hosting enabled)
# ==========================================================

resource "aws_s3_bucket" "site" {
  count         = var.enable_s3_site ? 1 : 0
  bucket_prefix = "${var.name}-site-"

  tags = merge(local.common_tags, { Name = "${var.name}-site" })
}

# Block ALL forms of public access (best practice)
resource "aws_s3_bucket_public_access_block" "site" {
  count  = var.enable_s3_site ? 1 : 0
  bucket = aws_s3_bucket.site[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload index.html
resource "aws_s3_object" "index" {
  count  = var.enable_s3_site ? 1 : 0
  bucket = aws_s3_bucket.site[0].id
  key    = "index.html"

  # Use path.root so it works even if this file is in a different folder than web/
  source       = "${path.root}/web/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.root}/web/index.html")

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# Upload style.css
resource "aws_s3_object" "css" {
  count  = var.enable_s3_site ? 1 : 0
  bucket = aws_s3_bucket.site[0].id
  key    = "style.css"

  source       = "${path.root}/web/style.css"
  content_type = "text/css"
  etag         = filemd5("${path.root}/web/style.css")

  depends_on = [aws_s3_bucket_public_access_block.site]
}
