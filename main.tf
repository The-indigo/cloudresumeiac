resource "aws_s3_bucket" "resumeBucket" {
  bucket = var.BUCKET_NAME
}

resource "aws_s3_bucket_policy" "allowCloudfrontAccess" {
  bucket = aws_s3_bucket.resumeBucket.id
  policy = data.aws_iam_policy_document.allowCloudfrontAccess.json
}

data "aws_iam_policy_document" "allowCloudfrontAccess" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    principals  {
       type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = ["s3:GetObject"]
    resources = ["arn:aws:s3:::ajdeyemiresumee/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::568305562431:distribution/E2OHB53YRRJ2UR"]
    }
  }
}

