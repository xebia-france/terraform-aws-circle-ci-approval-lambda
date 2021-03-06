resource "aws_api_gateway_rest_api" "approval" {
  name        = "CircleCiApproval"
  description = "Terraform Serverless Application Example"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.approval.id
  parent_id   = aws_api_gateway_rest_api.approval.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.approval.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.approval.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.approval.invoke_arn
 }

 resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.approval.id
   resource_id   = aws_api_gateway_rest_api.approval.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
 }

 resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.approval.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.approval.invoke_arn
 }

 resource "aws_api_gateway_deployment" "api_gw_approval_deploy" {
    depends_on = [
      aws_api_gateway_integration.lambda,
      aws_api_gateway_integration.lambda_root,
    ]

    rest_api_id = aws_api_gateway_rest_api.approval.id
    stage_name  = "production"
  }

  resource "aws_lambda_permission" "apigw" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.approval.function_name
    principal     = "apigateway.amazonaws.com"

    # The "/*/*" portion grants access from any method on any resource
    # within the API Gateway REST API.
    source_arn = "${aws_api_gateway_rest_api.approval.execution_arn}/*/*"
  }
