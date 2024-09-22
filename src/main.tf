## CRIAÇÂO DO API Gateway ##

provider "aws" {
  region = "us-east-1"
}

# Referenciar o Load Balancer existente
data "aws_lb" "api_lb" {
  name = "api-lb"  # Substitua pelo nome do seu Load Balancer existente
}

# Referenciar o listener HTTP associado ao Load Balancer
data "aws_lb_listener" "http_listener" {
  load_balancer_arn = data.aws_lb.api_lb.arn
  port              = 80
}

# API Gateway para Lanchonete
resource "aws_api_gateway_rest_api" "lanchonete" {
  name        = "Lanchonete"
  description = "API Gateway para Lanchonete"
}

resource "aws_api_gateway_authorizer" "lambda_authorizer" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  name        = "LambdaAuthorizer"
  type        = "REQUEST"
  authorizer_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_authorizer.arn}/invocations"
  identity_source = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 0  # Desativa o cache
}

# Recurso /lanchonete
resource "aws_api_gateway_resource" "lanchonete_resource" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  parent_id   = aws_api_gateway_rest_api.lanchonete.root_resource_id
  path_part   = "lanchonete"
}

# Recurso /pedido
resource "aws_api_gateway_resource" "pedido_resource" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  parent_id   = aws_api_gateway_resource.lanchonete_resource.id
  path_part   = "pedido"
}

# Recurso /cliente
resource "aws_api_gateway_resource" "cliente_resource" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  parent_id   = aws_api_gateway_resource.lanchonete_resource.id
  path_part   = "cliente"
}

# Método GET para /pedido com Lambda Authorizer
resource "aws_api_gateway_method" "get_pedido" {
  rest_api_id   = aws_api_gateway_rest_api.lanchonete.id
  resource_id   = aws_api_gateway_resource.pedido_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

# Método POST para /pedido com Lambda Authorizer
resource "aws_api_gateway_method" "post_pedido" {
  rest_api_id   = aws_api_gateway_rest_api.lanchonete.id
  resource_id   = aws_api_gateway_resource.pedido_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

# Método GET para /cliente/{cpf} com Lambda Authorizer
resource "aws_api_gateway_method" "get_cliente_by_cpf" {
  rest_api_id   = aws_api_gateway_rest_api.lanchonete.id
  resource_id   = aws_api_gateway_resource.cliente_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

# Método POST para /cliente com Lambda Authorizer
resource "aws_api_gateway_method" "post_cliente" {
  rest_api_id   = aws_api_gateway_rest_api.lanchonete.id
  resource_id   = aws_api_gateway_resource.cliente_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id
}

# Integração para o Load Balancer - GET Pedido
resource "aws_api_gateway_integration" "lb_integration_get_pedido" {
  rest_api_id             = aws_api_gateway_rest_api.lanchonete.id
  resource_id             = aws_api_gateway_resource.pedido_resource.id
  http_method             = aws_api_gateway_method.get_pedido.http_method
  type                    = "HTTP"
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.api_lb.dns_name}/api/pedido"  # Referência ao Load Balancer existente

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Integração para o Load Balancer - POST Pedido
resource "aws_api_gateway_integration" "lb_integration_post_pedido" {
  rest_api_id             = aws_api_gateway_rest_api.lanchonete.id
  resource_id             = aws_api_gateway_resource.pedido_resource.id
  http_method             = aws_api_gateway_method.post_pedido.http_method
  type                    = "HTTP"
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.api_lb.dns_name}/api/pedido"  # Referência ao Load Balancer existente

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Integração para o Load Balancer - GET Cliente
resource "aws_api_gateway_integration" "lb_integration_get_cliente" {
  rest_api_id             = aws_api_gateway_rest_api.lanchonete.id
  resource_id             = aws_api_gateway_resource.cliente_resource.id
  http_method             = aws_api_gateway_method.get_cliente_by_cpf.http_method
  type                    = "HTTP"
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.api_lb.dns_name}/api/cliente"  # Referência ao Load Balancer existente

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Integração para o Load Balancer - POST Cliente
resource "aws_api_gateway_integration" "lb_integration_post_cliente" {
  rest_api_id             = aws_api_gateway_rest_api.lanchonete.id
  resource_id             = aws_api_gateway_resource.cliente_resource.id
  http_method             = aws_api_gateway_method.post_cliente.http_method
  type                    = "HTTP"
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.api_lb.dns_name}/api/cliente"  # Referência ao Load Balancer existente

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Respostas de Método GET para /pedido
resource "aws_api_gateway_method_response" "get_pedido_method_response" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  resource_id = aws_api_gateway_resource.pedido_resource.id
  http_method = aws_api_gateway_method.get_pedido.http_method
  status_code = "200"
}

# Respostas de Integração GET para /pedido
resource "aws_api_gateway_integration_response" "get_pedido_integration_response" {
  rest_api_id   = aws_api_gateway_rest_api.lanchonete.id
  resource_id   = aws_api_gateway_resource.pedido_resource.id
  http_method   = aws_api_gateway_method.get_pedido.http_method
  status_code   = aws_api_gateway_method_response.get_pedido_method_response.status_code
}

# Respostas de Método POST para /pedido
resource "aws_api_gateway_method_response" "post_pedido_method_response" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  resource_id = aws_api_gateway_resource.pedido_resource.id
  http_method = aws_api_gateway_method.post_pedido.http_method
  status_code = "200"
}

# Respostas de Integração POST para /pedido
resource "aws_api_gateway_integration_response" "post_pedido_integration_response" {
  rest_api_id   = aws_api_gateway_rest_api.lanchonete.id
  resource_id   = aws_api_gateway_resource.pedido_resource.id
  http_method   = aws_api_gateway_method.post_pedido.http_method
  status_code   = aws_api_gateway_method_response.post_pedido_method_response.status_code
}

# Deploy da API no estágio "Prod"
resource "aws_api_gateway_deployment" "lanchonete_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lanchonete.id
  stage_name  = "Prod"

  depends_on = [
    aws_api_gateway_integration.lb_integration_get_pedido,
    aws_api_gateway_integration.lb_integration_post_pedido,
    aws_api_gateway_integration.lb_integration_get_cliente,
    aws_api_gateway_integration.lb_integration_post_cliente
  ]
}

# Output do endpoint da API Gateway
output "api_gateway_url" {
  description = "URL do API Gateway"
  value       = aws_api_gateway_deployment.lanchonete_deployment.invoke_url
}