variable "db_username" {
  description = "Aurora username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Aurora password"
  type        = string
  sensitive   = true
}
