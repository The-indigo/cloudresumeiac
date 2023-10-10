variable "REGION" {
  default = "ca-central-1"
}
variable "FE_BUCKET_NAME" {
default = "ajdeyemiresumee"   
}
variable "BE_BUCKET_NAME" {
default = "ajdeyemibebucket"   
}
variable "SOURCEPATH" {
  default = "/Users/indigo/Documents/aws/cloudresumebe"
}

variable "CERTIFICATEARN" {
  default= "arn:aws:acm:us-east-1:568305562431:certificate/60eb7f92-c757-4299-9683-f36bcb49313e"
}
variable "DYNAMODBARN" {
  default="arn:aws:dynamodb:ca-central-1:568305562431:table/visitcount"
}