variable "ENV" {
  default = "abr"
}

variable "REGION" {
  default = "us-east-1"
}


variable "VPC" {
  type = object({
    CIDR = string
    SUBNET_PRIVATE = list(string)
    SUBNET_PUBLIC = list(string)
    SUBNET_DB = list(string)
  })

  default = {
    "CIDR" = "140.30.0.0/16",
    "SUBNET_PRIVATE" = ["140.30.3.0/24", "140.30.4.0/24"],
    "SUBNET_DB" = ["140.30.5.0/24", "140.30.6.0/24"],
    "SUBNET_PUBLIC" = ["140.30.7.0/24", "140.30.8.0/24"]
  }
}
