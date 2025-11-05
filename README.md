## Setting Up Automated Database Monitoring with Infrastructure as Code

> Course: TECH 4060 - Technical Communication
>
> Assignment: Procedure Document
>
> Topic: Installing and Configuring a Local Database Monitoring System
>
> Time Required: 30-40 minutes (first time)

### Purpose and Audience

This procedure enables anyone with basic computer skills to set up a professional database monitoring system on their local Windows computer. By following these steps, you will deploy a PostgreSQL database with automated monitoring dashboards using industry-standard tools (Terraform, Docker, Prometheus, and Grafana).

**Who should use this procedure:**
- Computer science students learning DevOps practices
- Developers who want to understand Infrastructure as Code
- Anyone interested in database monitoring and visualization

**What you will learn:** 
- How to use Infrastructure as Code to automate deployments
- How to monitor database health with professional tools
- How to create visual dashboards that update in real-time

### What You Will Build

**By the end of this procedure, you will have:**

1. **PostgreSQL Database** => Running in a Docker container with persistent storage
2. **Prometheus** => Collecting database metrics every 5 seconds
3. **PostgreSQL Exporter** => Exposing database statistics for monitoring
4. **Grafana** => Providing visual dashboards showing database health and activity
5. **Infrastructure as Code** => All managed by Terraform (deploy/destroy with one command)

_All of this runs on your local machine_, no cloud accounts or external services required.

### Prerequisites
Before starting, you need to install three tools. Follow the instructions below in order.

#### Step 1: Prepare Your System Environment

Before installing any tools, make sure your computer is ready to run Docker and Terraform smoothly.

**Check System Requirements**

- Operating System: Windows 10 (21H2 or newer) or Windows 11
- RAM: Minimum 8 GB (16 GB recommended)
- Disk Space: At least 10 GB free
- Internet Connection: Required to download Docker images
- Enable Virtualization in BIOS To allow for the creation of VMs and containers, you have to have virtualization enabled.
  - Search for Advanced startup in your Windows settings
  - Click Restart now
  - Click Troubleshoot
  - Click UEFI Firmware Settings
  - Navigate through your BIOS to find Virtualization, enable it and restart your system
- Enable Windows Subsystem for Linux (WSL 2) Docker Desktop uses WSL 2 to run Linux containers.
  - Open PowerShell as Administrator
  - Run: ```wsl --install```
  - Restart your computer when prompted.
  - Verify installation: ```wsl --status```
  - You should see: "Default Version: 2"
- Install Visual Studio Code (Text Editor) This will make editing configuration files easier.
  - Go to: https://code.visualstudio.com/download
  - Download Windows (User Installer)
  - Run the installer and accept defaults
- Restart Your Computer This ensures WSL 2 and environment variables are fully applied before continuing.
- Open Windows Features (this is to ensure you have the necessary system settings enabled).
  - On your system, search for Windows Features
  - Look for Hyper-V and WSL
  - Enable all Hyper-V and WSL features
  - As prompted, restart your system to finish the setup if they were not already enabled

#### Step 2: Install Git (if not already installed)

Git is version control software. We’ll use Git Bash as our command-line terminal.

- Check if Git is installed:
  - Open Command Prompt
  - Run: ```git --version```
  - If you see a version number, Git is already installed => **skip to Section 2**
- Download Git:
  - Go to: [https://git-scm.com/download/win](https://git-scm.com/download/win)
  - Download will start automatically (`~50 MB`)
- Install Git:
  - Run the installer
  - Accept all default options
  - Click "Next" through all screens
  - Click "Install"
- Verify Git is installed:
  - Open Git Bash from the Start menu
  - Run: ```git --version```
  - You should see: `git version 2.x.x` (or similar)

#### Step 3: Install Docker Desktop

- Download Docker Desktop:
  - Go to: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
  - Click "Download for Windows"
  - File size: `~500 MB`
- Install Docker Desktop:
  - Run the downloaded installer
  - Accept the default options
  - When prompted, select "Use WSL 2 instead of Hyper-V"
  - Click "Install"
  - Restart your computer when prompted
- Start Docker Desktop:
  - Open Docker Desktop from the Start menu
  - Wait for it to say "Docker Desktop is running" (green icon in system tray)
  - This may take 1-2 minutes the first time
- Verify Docker is working:
  - Open Git Bash (or PowerShell)
  - Run: ```docker --version```
  - You should see: `Docker version 24.x.x` (or similar)

> [!WARNING]
> **Important:** Docker Desktop must be running before you can proceed. You’ll see the whale icon in your system tray.

#### Step 4: Install Terraform

Terraform is an Infrastructure as Code tool that lets you define and manage infrastructure using configuration files.

- Download Terraform:
  - Go to: [https://www.terraform.io/downloads](https://www.terraform.io/downloads)
  - Click "Windows" under "Binary Download"
  - Download the ZIP file (`~50 MB`)
- Install Terraform:
  - Extract the ZIP file
  - You’ll see one file: `terraform.exe`
- Move terraform.exe to: `C:\Windows\System32\`
  - This makes Terraform available from any folder
- Verify Terraform is installed:
  - Open a new Git Bash window
  - Run: ```terraform --version```
  - You should see: `Terraform v1.x.x` (or similar)

### Section 1: Create Project Structure

Now that you have the required tools, let’s create the project files.

#### Step 5: Create Project Directory

1. Open Visual Studio Code
2. Open a New Terminal in VS Code:
  a. In the top menu, click Terminal → New Terminal
  b. A terminal will open at the bottom of VS Code
  c. By default, this uses PowerShell
  d. Navigate to your Documents folder: ```cd $env:USERPROFILE\Documents```
3. Create the project structure: ```mkdir tech4060-procedure\terraform -Force```
  a. Navigate into the terraform folder: ```cd tech4060-procedure\terraform```
4. Verify you’re in the correct location: ```pwd```
  a. You should see something similar to: `C:\Users\YourName\Documents\tech4060-procedure\terraform`

#### Step 6: Create Terraform Configuration Files

You’ll create 4 files that define your infrastructure. Copy each file exactly as shown.

**File 1: main.tf**

This file defines what infrastructure to create (database, monitoring tools).
```
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
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
```

**File 2: variables.tf**
This file defines configuration variables (database name, passwords, etc.).
variables.tf
```
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
```

**File 3: outputs.tf**
This file defines what information to display after deployment (URLs, connection info).
outputs.tf
```
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
```

**File 4: prometheus.yml**
This file configures Prometheus to collect metrics from the database.
prometheus.yml
```
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # PostgreSQL database metrics
  - job_name: 'postgresql'
    scrape_interval: 5s
    static_configs:
      - targets: ['host.docker.internal:9187']
        labels:
          database: 'dev_db'
          environment: 'development'
```

**File 5: .gitignore**

This prevents sensitive files from being tracked in version control.
.gitignore
```
terraform.tfvars
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
postgres_data/
prometheus_data/
grafana_data/
```

#### Step 7: Verify Files Were Created
In your terminal, write the following command: ```ls -la```
You should see these 5 files: 
- `main.tf`
- `variables.tf`
- `outputs.tf`
- `prometheus.yml`
- `.gitignore`

If any are missing, go back and recreate them.

### Section 2: Deploy the Infrastructure

Now we’ll use Terraform to deploy everything automatically.

#### Step 8: Initialize Terraform

This downloads the Docker provider plugin.
```
terraform init
```
```
// Expected output:
Initializing the backend...
Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "~> 3.0"...
- Installing kreuzwerker/docker v3.0.2...

Terraform has been successfully initialized!
```

> This takes 10-20 seconds

#### Step 8: Review the Deployment Plan
This shows what Terraform will create (without actually creating it).

```
terraform plan
```
```
Expected output:
Plan: 8 to add, 0 to change, 0 to destroy.
```

**What this means:** 
- 4 Docker images will be downloaded
- 4 Docker containers will be created
- Nothing will be changed or destroyed (since this is the first run)

#### Step 9: Deploy Everything

This command actually creates the infrastructure.
```
terraform apply
```
**What happens next:** 
1. Terraform shows the plan again
2. You’ll see: "Do you want to perform these actions?"
3. Type: `yes`
4. Press `Enter`

**Deployment process (3-5 minutes):**
You’ll see:
```
docker_image.postgres: Creating...
docker_image.prometheus: Creating...
docker_image.grafana: Creating...
docker_image.postgres_exporter: Creating...
```
Then:
```
docker_container.postgres: Creating...
docker_container.postgres_exporter: Creating...
docker_container.prometheus: Creating...
docker_container.grafana: Creating...
```
**Success looks like:**
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
```

**Outputs:**
```
database_endpoint = "localhost:5432"
database_name = "dev_db"
database_user = "dev_user"
grafana_url = "http://localhost:3000"
prometheus_url = "http://localhost:9090"
```

#### Step 10: Verify Everything is Running

Check that all 4 containers are running:
```
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
**Expected output:**
```
NAMES               STATUS              PORTS
grafana             Up 2 minutes        0.0.0.0:3000->3000/tcp
prometheus          Up 2 minutes        0.0.0.0:9090->9090/tcp
postgres_exporter   Up 2 minutes        0.0.0.0:9187->9187/tcp
dev_postgres        Up 2 minutes        0.0.0.0:5432->5432/tcp
```
All containers should show "Up"

### Section 3: Create Sample Data

Before we can see anything in the monitoring dashboards, we need data in the database.

#### Step 11: Create a Users Table

```
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT, email TEXT);"
```
Expected output: `CREATE TABLE`

#### Step 12: Insert Sample Users

This adds 100 users to the database:
```
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "
INSERT INTO users (name, email)
SELECT 'User' || generate_series, 'user' || generate_series || '@example.com'
FROM generate_series(1, 100);
"
```
Expected output: `INSERT 0 100`

#### Step 13: Verify Data Was Created

```
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "SELECT COUNT(*) FROM users;"
```
Expected output:
```
 count 
-------
   100
(1 row)
```

### Section 4: Set Up Grafana Dashboard

Now we’ll create visual dashboards to monitor the database.

#### Step 14: Access Grafana
- Open your web browser
- Go to: [http://localhost:3000](http://localhost:3000)
- Login with:
  - Username: admin
  - Password: admin123
- You should see the Grafana home page.

#### Step 15: Add Prometheus Data Source

Grafana needs to know where to get the metrics from.

- Click "Connections" in the left sidebar
- Click "Data sources"
- Click "Add data source" (blue button)
- Select "Prometheus"
- In the URL field, enter: `http://host.docker.internal:9090`
- Scroll to the bottom
- Click "Save & Test"

You should see: "Successfully queried the Prometheus API" (green checkmark)

#### Step 16: Create Your First Dashboard

- Click the "+" icon in the left sidebar
- Select "Create Dashboard"
- Click "Add visualization"
- Select "Prometheus" as the data source

#### Step 17: Create Panel 1 - Database Status
This panel shows if the database is running (green) or down (red).

- Panel title: Click "Panel Title" at top, change to: Database Status
- Query: In the query box at bottom, enter: ```pg_up```
- Visualization type: Click "Time series" dropdown, select "Stat"
- Color thresholds:
  - Click the "Thresholds" tab on right
  - Set: Red (0), Green (1)
  - Click "Apply" (top right)

You should see a green "1" meaning database is UP!

#### Step 18: Create Panel 2 - Total Users

- Click "Add" → "Visualization"
- Panel title: Total Users in Database
- Query: ```pg_stat_database_tup_inserted{datname="dev_db"}`
- Visualization: Stat
- Unit: On right side, under "Standard options", set Unit to "short"
- Click "Apply"

You should see "158" or similar (the number of rows inserted)

#### Step 19: Create Panel 3 - Transaction Rate
This shows database activity as a graph over time.

- Click "Add" → "Visualization"
- Panel title: Database Transaction Rate
- Query: ```rate(pg_stat_database_xact_commit{datname="dev_db"}[1m])```
- Visualization: Time series (default)
- Unit: Set to "ops/sec"
- Click "Apply"

You should see a graph (may be flat if no activity recently)

#### Step 20: Create Panel 4 - Active Connections

- Click "Add" → "Visualization"
- Panel title: Active Database Connections
- Query: ```pg_stat_database_numbackends{datname="dev_db"}```
- Visualization: Gauge
- Min: 0, Max: 100
- Click "Apply"

You should see a gauge showing current connections (probably 2-5)

#### Step 21: Save Your Dashboard

- Click the disk icon (top right) to save
- Name: Database Monitoring Dashboard
- Click "Save"

#### Step 22: Configure Auto-Refresh

**Make the dashboard update automatically:**

- In the top-right corner, click the time range dropdown (shows "Last 6 hours")
  - Change to: "Last 5 minutes"
- Click the refresh dropdown (circular arrow icon)
  - Select: "5s" (refresh every 5 seconds)

Now your dashboard will update automatically!

### Section 5: Generate Live Activity

Let’s create database activity to see the monitoring in action.

#### Step 23: Insert Data in Real-Time

Run this command and watch your Grafana dashboard:
```
for i in {200..250}; do
    docker exec -it dev_postgres psql -U dev_user -d dev_db -c "INSERT INTO users (name, email) VALUES ('User$i', 'user$i@example.com');"
    echo "Inserted User$i - Check Grafana!"
    sleep 2
done
```

What you should see: 
- The "Total Users" number increasing
- The "Transaction Rate" graph spiking 
- Real-time updates every 5 seconds

Congratulations! Your monitoring system is working!

### Section 6: Understanding What You Built

**Infrastructure as Code Benefits**
What you just did would traditionally require: 
- Manual Docker installation 
- Hand-typing docker run commands with 20+ parameters 
- Manual configuration of Prometheus 
- Manual setup of Grafana 
- Hours of troubleshooting

With Infrastructure as Code (Terraform), you did all of this with one command: `terraform apply`

**Key Concepts Demonstrated**

1. **Automation:** No manual clicking or configuration
2. **Reproducibility:** Anyone can run terraform apply and get identical results
3. **Version Control:** All configuration is in text files (can be tracked in Git)
4. **Documentation:** The Terraform files themselves document your infrastructure
5. **Observability:** Professional monitoring tools used by companies like Netflix, Uber, and Airbnb

### Section 7: Management Commands

View Current Infrastructure

**See what Terraform is managing:**
```
terraform show
```

**See outputs (URLs, endpoints)**
```
terraform output
```
**Stop Everything (But Keep Data) -> Stop all containers:**
```
docker stop dev_postgres postgres_exporter prometheus grafana
```

**Start Everything Again -> Start all containers**
```
docker start dev_postgres postgres_exporter prometheus grafana
```

**Completely Remove Everything**
```
terraform destroy
```
Type `yes` when prompted. This removes all containers and frees up disk space.

> ![WARNING]
> This deletes all data. The local folders (postgres_data, prometheus_data, grafana_data) will remain and can be manually deleted.


## Additional Resources

- Docker Documentation: [https://docs.docker.com/](https://docs.docker.com/)
- Terraform Tutorial: [https://learn.hashicorp.com/terraform](https://learn.hashicorp.com/terraform)
- Prometheus Documentation: [https://prometheus.io/docs/](https://prometheus.io/docs/)
- Grafana Tutorials: [https://grafana.com/tutorials/](https://grafana.com/tutorials/)
- PostgreSQL Guide: [https://www.postgresql.org/docs/](https://www.postgresql.org/docs/)

