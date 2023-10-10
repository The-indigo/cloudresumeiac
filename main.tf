resource "aws_s3_bucket" "resumeBucket" {
  bucket = var.FE_BUCKET_NAME
}

resource "aws_s3_bucket" "lambdaCountBucket" {
  bucket = var.BE_BUCKET_NAME
}

# resource "aws_s3_bucket_policy" "allowCloudfrontAccess" {
#   bucket = aws_s3_bucket.resumeBucket.id
#   policy = data.aws_iam_policy_document.allowCloudfrontAccess.json
# }
resource "aws_s3_object" "lambdaCountObject" {
bucket = aws_s3_bucket.lambdaCountBucket.id
key= "cloudresumebe.zip"
source = data.archive_file.lambdaCountFunction.output_path
etag = filemd5(data.archive_file.lambdaCountFunction.output_path)
}



resource "aws_lambda_function" "visitorCount" {
  function_name = "insertCount"

  s3_bucket = aws_s3_bucket.lambdaCountBucket.id
  s3_key    = aws_s3_object.lambdaCountObject.key

  runtime = "python3.9"
  handler = "handler.insertCount"

  source_code_hash = data.archive_file.lambdaCountFunction.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "visitorCount" {
  name = "/aws/lambda/${aws_lambda_function.visitorCount.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}




# data "aws_iam_policy_document" "allowCloudfrontAccess" {
#   statement {
#     sid       = "AllowCloudFrontServicePrincipal"
#     effect    = "Allow"
#     principals  {
#        type        = "Service"
#         identifiers = ["cloudfront.amazonaws.com"]
#     }
#     actions = ["s3:GetObject"]
#     resources = ["arn:aws:s3:::ajdeyemiresumee/*"]
#     condition {
#       test     = "StringEquals"
#       variable = "AWS:SourceArn"
#       values   = ["arn:aws:cloudfront::568305562431:distribution/E2OHB53YRRJ2UR"]
#     }
#   }
# }



data "archive_file" "lambdaCountFunction" {
    type = "zip"
    source_dir = var.SOURCEPATH
    output_path = "${path.module}/cloudresumebe.zip"
}