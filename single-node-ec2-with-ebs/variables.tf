variable "aws_credentials_file" {
    type = string
    default = "~/.aws/credentials"
}

variable "aws_config_file" {
    type = string
    default = "~/.aws/config"
}

variable "aws_profile" {
    type = string
    default = "default"
}

variable name_prefix {
    type = string
}

variable "key_name" {
    type = string
}

variable "instance_keypair_file" {
    type = string 
}

variable "instance_type" {
    type = string
    default = "t2.xlarge"
}

variable "root_device_size" {
    type = number
    default = 50
}

variable "ebs_device_size" {
    type = number
    default = 50
}