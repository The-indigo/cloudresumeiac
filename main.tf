resource "aws_s3_bucket" "resumeBucket" {
  bucket = var.FE_BUCKET_NAME
}

resource "aws_s3_bucket" "lambdaCountBucket" {
  bucket = var.BE_BUCKET_NAME
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

data "archive_file" "lambdaCountFunction" {
    type = "zip"
    source_dir = var.SOURCEPATH
    output_path = "${path.module}/cloudresumebe.zip"
}

resource "aws_s3_object" "lambdaCountBucket" {
bucket = aws_s3_bucket.lambdaCountBucket.id
key= "cloudresumebe.zip"
source = data.archive_file.lambdaCountFunction.output_path
etag = filemd5(data.archive_file.lambdaCountFunction.output_path)
}