resource "aws_security_group" "sg" {
  name        = var.NAME
  vpc_id      = var.VPC_ID

  dynamic "ingress" {
    for_each = var.INGRESS_RULES

    content {
      from_port        = ingress.value.PORT
      to_port          = ingress.value.PORT
      protocol         = "tcp"
      cidr_blocks      = ingress.value.CIDR_BLOCKS
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}