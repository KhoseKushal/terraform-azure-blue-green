variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

#vnet 
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "vnet-blue-green"
}

variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "subnet-app"
}

variable "subnet_address_prefix" {
  description = "Subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

#nsg
variable "nsg_name" {
  description = "Network Security Group name"
  type        = string
  default     = "nsg-blue-green"
}

#frontend ip and lb
variable "public_ip_name" {
  description = "Public IP name"
  type        = string
  default     = "pip-blue-green"
}

variable "lb_name" {
  description = "Load Balancer name"
  type        = string
  default     = "lb-blue-green"
}

variable "frontend_ip_name" {
  description = "Load balancer frontend IP name"
  type        = string
  default     = "lb-frontend"
}

#backend pool
variable "blue_backend_pool_name" {
  description = "Blue backend pool name"
  type        = string
  default     = "blue-backend-pool"
}

variable "green_backend_pool_name" {
  description = "Green backend pool name"
  type        = string
  default     = "green-backend-pool"
}

variable "health_probe_name" {
  description = "Health probe name"
  type        = string
  default     = "http-probe"
}

variable "lb_rule_name" {
  description = "Load balancer rule name"
  type        = string
  default     = "http-rule"
}

#vm
variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}
