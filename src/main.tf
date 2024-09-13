resource "aws_api_gateway_rest_api" "lanchonete" {
  name        = "Lanchonete"
  description = "API Gateway para Lanchonete"
}

resource "aws_api_gateway_resource" "lanchonete_resource" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  parent_id   = aws_api_gateway_rest_api.lanchonete.root_resource_id
  path_part   = "lanchonete"
}

resource "aws_api_gateway_resource" "pedido_resource" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  parent_id   = aws_api_gateway_resource.lanchonete_resource.id
  path_part   = "pedido"
}

# Método GET com o Lambda Authorizer
resource "aws_api_gateway_method" "get_pedido" {
  rest_api_id   = aws_api_gateway_rest_api.lanchonete.id
  resource_id   = aws_api_gateway_resource.pedido_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"  # Custom authorization via Lambda
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id  # Lambda Authorizer ID
}

# Lambda Authorizer
resource "aws_api_gateway_authorizer" "lambda_authorizer" {
  rest_api_id    = aws_api_gateway_rest_api.lanchonete.id
  name           = "LambdaAuthorizer"
  type           = "REQUEST"
  authorizer_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.authorizer_function.arn}/invocations"
  identity_source = "method.request.header.cpf"
  authorizer_result_ttl_in_seconds = 0 # Desativa o cache
}

# Integração MOCK simples
resource "aws_api_gateway_integration" "mock_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lanchonete.id
  resource_id             = aws_api_gateway_resource.pedido_resource.id
  http_method             = aws_api_gateway_method.get_pedido.http_method
  type                    = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Resposta do método
resource "aws_api_gateway_method_response" "get_pedido_method_response" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  resource_id = aws_api_gateway_resource.pedido_resource.id
  http_method = aws_api_gateway_method.get_pedido.http_method
  status_code = "200"
}

# Resposta da integração
resource "aws_api_gateway_integration_response" "mock_integration_response" {
  rest_api_id   = aws_api_gateway_rest_api.lanchonete.id
  resource_id   = aws_api_gateway_resource.pedido_resource.id
  http_method   = aws_api_gateway_method.get_pedido.http_method
  status_code   = aws_api_gateway_method_response.get_pedido_method_response.status_code
}

# Deploy da API no estágio "Prod"
resource "aws_api_gateway_deployment" "lanchonete_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  stage_name  = "Prod"

  # Recria o deploy quando os métodos mudam
  depends_on = [
    aws_api_gateway_integration.mock_integration,
    aws_api_gateway_method.get_pedido
  ]
}