variable "PROJECT" {
  type = string
}

variable "PREFIX" {
  type    = string
  default = "jmeter"
}

variable "SHARE_NAME" {
  type = string
}

variable "JMETER_WORKERS_COUNT" {
  type    = number
  default = 1
}

variable "JMETER_WORKER_CPU" {
  type    = string
  default = "2.0"
}

variable "JMETER_WORKER_MEMORY" {
  type    = string
  default = "8.0"
}

variable "JMETER_CONTROLLER_CPU" {
  type    = string
  default = "2.0"
}

variable "JMETER_CONTROLLER_MEMORY" {
  type    = string
  default = "8.0"
}

variable "JMETER_DOCKER_IMAGE" {
  type    = string
  default = "justb4/jmeter:5.1.1"
}

variable "JMETER_STORAGE_QUOTA_GIGABYTES" {
  type    = number
  default = 1
}

variable "JMETER_DOCKER_PORT" {
  type    = number
  default = 1099
}

variable "JMETER_ACR_NAME" {
  type    = string
  default = "DevopsjmeterRegistry"
}

variable "JMETER_ACR_RESOURCE_GROUP_NAME" {
  type    = string
  default = "DevOps-Team-RG"
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

variable "AZ_DEVOPS_TOKEN" {
  type      = string
  sensitive = true
}

variable "AZ_DEVOPS_URL" {
  type      = string
  sensitive = true
}

variable "LOCATION" {
  type    = string
  default = "West Europe"
}

variable "JMETER_JMX_FILE" {
  type = string
}

variable "JMETER_MOUNT_PATH" {
  type    = string
  default = "/jmeter"
}

variable "JMETER_RESULTS_FOLDER" {
  type    = string
  default = "/jmeter/results"
}

variable "JMETER_RESULTS_FILE" {
  type    = string
  default = "/jmeter/results/results.jtl"
}

variable "JUNIT_RESULTS" {
  type    = string
  default = "/jmeter/results/output.xml"
}

variable "JMETER_DASHBOARD_FOLDER" {
  type    = string
  default = "/jmeter/dashboard"
}
