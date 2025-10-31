variable "db_name" {
  description = "Database name"
  type        = string
  default     = "dev_db"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "dev_user"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "dev_password_123"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123"
}
