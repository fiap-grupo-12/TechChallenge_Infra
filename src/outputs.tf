output "api_gateway_id" {
  value = aws_api_gateway_rest_api.lanchonete.id
}

output "lanchonete_resource_id" {
  value = aws_api_gateway_resource.lanchonete_resource.id
}

output "pedido_resource_id" {
  value = aws_api_gateway_resource.pedido_resource.id
}

# Saída com a URL da API Gateway no ambiente Prod
output "api_url_prod" {
  value = "https://${aws_api_gateway_rest_api.lanchonete.id}.execute-api.${var.region}.amazonaws.com/Prod"
  description = "A URL da API Gateway no ambiente Prod"
}