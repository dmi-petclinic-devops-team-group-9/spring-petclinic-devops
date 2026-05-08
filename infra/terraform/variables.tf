variable "project_prefix" {
  description = "petclinic11"
  type        = string
}
variable "location" {
  type    = string
  default = "westeurope"
}
variable "node_count" {
  type    = number
  default = 2
}
variable "node_vm_size" {
  type    = string
  default = "Standard_B2s_v2"
}
