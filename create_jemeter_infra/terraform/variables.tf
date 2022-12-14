variable "RESOURCE_GROUP_NAME" {
  type    = string
  default = "Jmeter_Resource_Project"
}

variable "LOCATION" {
  type    = string
  default = "West Europe"
}

variable "PROJECT" {
  type    = string
  default = "AZU1730"
}

variable "PREFIX" {
  type    = string
  default = "jmeter"
}

variable "SUBNET_ADDRESS_PREFIX" {
  type    = string
  default = "10.1.0.0/27"
}

variable "JMETER_STORAGE_QUOTA_GIGABYTES" {
  type    = number
  default = 1
}

variable "PERFORMANCE_TEST_VNET_RESOURCE_GROUP" {
  type    = string
  default = "DevOps-Team-RG"
}

variable "PERFORMANCE_TEST_VNET" {
  type    = string
  default = "DevOps-Vnet"
}

variable "PERFORMANCE_TEST_SUBNET" {
  type    = string
  default = "PerfomanceTest"
}

variable "DEVOPS_TEAM_RESOURCE_GROUP" {
  type    = string
  default = "DevOps-Team-RG"
}

variable "DEVOPS_TEAM_VNET" {
  type    = string
  default = "DevOps-Vnet"
}

variable "DEVOPS_TEAM_SUBNET" {
  type    = string
  default = "default"
}

variable "AZ_DEVOPS_TOKEN" {
  type      = string
  sensitive = true
}

variable "AZ_DEVOPS_URL" {
  type      = string
  sensitive = true
}
