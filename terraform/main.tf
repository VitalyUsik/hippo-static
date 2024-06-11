provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "static_site" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.bucket_name}"
}

resource "aws_s3_bucket_policy" "allow_bucket_access_from_cloudfront" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.allow_bucket_access_from_cloudfront.json
}

data "aws_iam_policy_document" "allow_bucket_access_from_cloudfront" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.static_site.arn,
      "${aws_s3_bucket.static_site.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_website_configuration" "static_site_config" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "static_site_bucket_ownership" {
  bucket = aws_s3_bucket.static_site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "static_site_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.static_site_bucket_ownership]

  bucket = aws_s3_bucket.static_site.id
  acl    = "private"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "OAI for S3 bucket"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.static_site.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.static_site.id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code            = 404
    response_page_path    = "/error.html"
    response_code         = 200
    error_caching_min_ttl = 300
  }
}

resource "aws_route53_record" "www" {
  count    = var.environment == "prod" ? 1 : 0
  zone_id  = var.zone_id
  name     = var.domain_name
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static_site.bucket
  key    = "index.html"
  source = "${path.module}/../website/index.html"
  etag   = filemd5("${path.module}/../website/index.html")
  acl    = "private"
  content_type = "text/html"
}

resource "aws_s3_object" "hippo1" {
  bucket = aws_s3_bucket.static_site.bucket
  key    = "images/hippo1.webp"
  source = "${path.module}/../website/images/hippo1.webp"
  etag   = filemd5("${path.module}/../website/images/hippo1.webp")
  acl    = "private"
  content_type = "image/webp"
}

resource "aws_s3_object" "hippo2" {
  bucket = aws_s3_bucket.static_site.bucket
  key    = "images/hippo2.webp"
  source = "${path.module}/../website/images/hippo2.webp"
  etag   = filemd5("${path.module}/../website/images/hippo2.webp")
  acl    = "private"
  content_type = "image/webp"
}

resource "aws_s3_object" "error_html" {
  bucket = aws_s3_bucket.static_site.bucket
  key    = "error.html"
  source = "${path.module}/../website/error.html"
  etag   = filemd5("${path.module}/../website/error.html")
  acl    = "private"
  content_type = "text/html"
}

resource "aws_s3_object" "error_hippo" {
  bucket = aws_s3_bucket.static_site.bucket
  key    = "images/error_hippo.webp"
  source = "${path.module}/../website/images/error_hippo.webp"
  etag   = filemd5("${path.module}/../website/images/error_hippo.webp")
  acl    = "private"
  content_type = "image/webp"
}