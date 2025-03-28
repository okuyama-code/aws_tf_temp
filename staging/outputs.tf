output "api_static_ip" {
  value = aws_lightsail_static_ip.my-app.ip_address
}
