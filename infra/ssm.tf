data "aws_ssm_parameter" "openai_api_key" {
  name = "/${var.namespace}/openai_api_key"
}

data "aws_ssm_parameter" "stream_key_name" {
  name = "/${var.namespace}/stream_key_name"
}
