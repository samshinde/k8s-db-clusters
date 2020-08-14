variable "region" {
  default = "us-east-1"
}

variable "ami" {
  default = "ami-07d0cf3af28718ef8"
}

variable "access_key" {
  default = "<ACCESS>"
  description = "IAM Access Key"
}

variable "secret_key" {
  default = "<SECRET>"
  description = "IAM Secret Key"
}