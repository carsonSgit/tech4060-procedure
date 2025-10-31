output "database_endpoint" {
  description = "Database connection address"
  value       = "localhost:${docker_container.postgres.ports[0].external}"
}

output "database_name" {
  value = var.db_name
}

output "database_user" {
  value = var.db_user
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.db_user}:${var.db_password}@localhost:${var.db_port}/${var.db_name}"
  sensitive   = true
}

output "prometheus_url" {
  description = "Prometheus web interface"
  value       = "http://localhost:9090"
}

output "grafana_url" {
  description = "Grafana web interface"
  value       = "http://localhost:3000"
}

output "grafana_credentials" {
  description = "Grafana login credentials"
  value       = "Username: admin, Password: ${var.grafana_admin_password}"
  sensitive   = true
}

output "postgres_exporter_metrics" {
  description = "PostgreSQL metrics endpoint"
  value       = "http://localhost:9187/metrics"
}

output "monitoring_endpoints" {
  description = "All monitoring endpoints"
  value = {
    prometheus = "http://localhost:9090"
    grafana    = "http://localhost:3000"
    exporter   = "http://localhost:9187/metrics"
  }
}
