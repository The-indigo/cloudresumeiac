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
#  This is an Aws managed role that allows the lambda function to write to cloudwatch logs
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda_dynamodb_policy"
  description = "Policy for Lambda to access DynamoDB"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query", 
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:dynamodb:ca-central-1:568305562431:table/visitcount"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attachment" {
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
  role       = aws_iam_role.lambda_exec.name
}


resource "aws_apigatewayv2_api" "visitorCountApiGateway" {
  name          = "visitorCountApiGateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "visitorCountApiGateway" {
  api_id = aws_apigatewayv2_api.visitorCountApiGateway.id

  name        = "visitorCountApiGatewaystage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "visitorCount" {
  api_id = aws_apigatewayv2_api.visitorCountApiGateway.id

  integration_uri    = aws_lambda_function.visitorCount.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "visitorCount" {
  api_id = aws_apigatewayv2_api.visitorCountApiGateway.id

  route_key = "POST /count"
  target    = "integrations/${aws_apigatewayv2_integration.visitorCount.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.visitorCountApiGateway.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitorCount.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.visitorCountApiGateway.execution_arn}/*/*"
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