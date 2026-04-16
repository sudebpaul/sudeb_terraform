output "ec2_ip" {
  value = aws_instance.node.public_ip
}