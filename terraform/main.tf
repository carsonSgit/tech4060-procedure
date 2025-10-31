terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # Windows Docker Desktop configuration
  host = "npipe:////.//pipe//docker_engine"
}

# Pull PostgreSQL image
resource "docker_image" "postgres" {
  name         = "postgres:15-alpine"
  keep_locally = true
}

# Create PostgreSQL container
resource "docker_container" "postgres" {
  name  = "dev_postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  ports {
    internal = 5432
    external = var.db_port
  }

  volumes {
    host_path      = "${abspath(path.root)}/postgres_data"
    container_path = "/var/lib/postgresql/data"
  }

  restart = "always"
}

# Pull Prometheus image
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

# Pull Grafana image
resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}

# Pull PostgreSQL Exporter for Prometheus
resource "docker_image" "postgres_exporter" {
  name         = "quay.io/prometheuscommunity/postgres-exporter:latest"
  keep_locally = true
}

# PostgreSQL Exporter - exposes database metrics
resource "docker_container" "postgres_exporter" {
  name  = "postgres_exporter"
  image = docker_image.postgres_exporter.image_id

  env = [
    "DATA_SOURCE_NAME=postgresql://${var.db_user}:${var.db_password}@host.docker.internal:5432/${var.db_name}?sslmode=disable"
  ]

  ports {
    internal = 9187
    external = 9187
  }

  restart = "always"

  # Wait for PostgreSQL to be ready
  depends_on = [docker_container.postgres]
}

# Prometheus - metrics collection and storage
resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    host_path      = "${abspath(path.root)}/prometheus_data"
    container_path = "/prometheus"
  }

  volumes {
    host_path      = "${abspath(path.root)}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.console.libraries=/usr/share/prometheus/console_libraries",
    "--web.console.templates=/usr/share/prometheus/consoles"
  ]

  restart = "always"

  depends_on = [docker_container.postgres_exporter]
}

# Grafana - visualization and dashboards
resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false"
  ]

  ports {
    internal = 3000
    external = 3000
  }

  volumes {
    host_path      = "${abspath(path.root)}/grafana_data"
    container_path = "/var/lib/grafana"
  }

  restart = "always"

  depends_on = [docker_container.prometheus]
}

