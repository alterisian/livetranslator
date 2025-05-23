data "aws_ssm_parameter" "openai_api_key" {
  name = "/${var.namespace}/openai_api_key"
}
