output "public_instance_public_ip" {
  value = aws_instance.public[*].public_ip
}