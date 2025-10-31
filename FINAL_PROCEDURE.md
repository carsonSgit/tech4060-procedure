# Setting Up Automated Database Monitoring with Infrastructure as Code

**Course:** TECH 4060 - Technical Communication  
**Assignment:** Procedure Document  
**Topic:** Installing and Configuring a Local Database Monitoring System  
**Time Required:** 30-40 minutes (first time)

---

## Purpose and Audience

This procedure enables anyone with basic computer skills to set up a professional database monitoring system on their local Windows computer. By following these steps, you will deploy a PostgreSQL database with automated monitoring dashboards using industry-standard tools (Terraform, Docker, Prometheus, and Grafana).

**Who should use this procedure:**
- Computer science students learning DevOps practices
- Developers who want to understand Infrastructure as Code
- Anyone interested in database monitoring and visualization

**What you will learn:**
- How to use Infrastructure as Code to automate deployments
- How to monitor database health with professional tools
- How to create visual dashboards that update in real-time

---

## What You Will Build

By the end of this procedure, you will have:

1. **PostgreSQL Database** - Running in a Docker container with persistent storage
2. **Prometheus** - Collecting database metrics every 5 seconds
3. **PostgreSQL Exporter** - Exposing database statistics for monitoring
4. **Grafana** - Providing visual dashboards showing database health and activity
5. **Infrastructure as Code** - All managed by Terraform (deploy/destroy with one command)

**All of this runs on your local machine - no cloud accounts or external services required.**

---

## Prerequisites

Before starting, you need to install three tools. Follow the instructions below in order.

### Step 1: Install Docker Desktop

Docker allows you to run applications in containers - isolated environments that work the same on any computer.

1. **Download Docker Desktop:**
   - Go to: https://www.docker.com/products/docker-desktop/
   - Click **"Download for Windows"**
   - File size: ~500 MB

2. **Install Docker Desktop:**
   - Run the downloaded installer
   - Accept the default options
   - When prompted, select **"Use WSL 2 instead of Hyper-V"** (recommended)
   - Click **"Install"**
   - Restart your computer when prompted

3. **Start Docker Desktop:**
   - Open Docker Desktop from the Start menu
   - Wait for it to say **"Docker Desktop is running"** (green icon in system tray)
   - This may take 1-2 minutes the first time

4. **Verify Docker is working:**
   - Open Git Bash (or PowerShell)
   - Run: `docker --version`
   - You should see: `Docker version 24.x.x` (or similar)

⚠️ **Important:** Docker Desktop must be running before you can proceed. You'll see the whale icon in your system tray.

---

### Step 2: Install Terraform

Terraform is an Infrastructure as Code tool that lets you define and manage infrastructure using configuration files.

1. **Download Terraform:**
   - Go to: https://www.terraform.io/downloads
   - Click **"Windows"** under "Binary Download"
   - Download the ZIP file (~50 MB)

2. **Install Terraform:**
   - Extract the ZIP file
   - You'll see one file: `terraform.exe`
   - Move `terraform.exe` to: `C:\Windows\System32\`
     - This makes Terraform available from any folder

3. **Verify Terraform is installed:**
   - Open a new Git Bash window
   - Run: `terraform --version`
   - You should see: `Terraform v1.x.x` (or similar)

---

### Step 3: Install Git (if not already installed)

Git is version control software. We'll use Git Bash as our command-line terminal.

1. **Check if Git is installed:**
   - Open Command Prompt
   - Run: `git --version`
   - If you see a version number, Git is already installed - **skip to Section 2**

2. **Download Git:**
   - Go to: https://git-scm.com/download/win
   - Download will start automatically (~50 MB)

3. **Install Git:**
   - Run the installer
   - Accept all default options
   - Click **"Next"** through all screens
   - Click **"Install"**

4. **Verify Git is installed:**
   - Open **Git Bash** from the Start menu
   - Run: `git --version`
   - You should see: `git version 2.x.x` (or similar)

---

## Section 1: Create Project Structure

Now that you have the required tools, let's create the project files.

### Step 4: Create Project Directory

1. **Open Git Bash**

2. **Navigate to your Documents folder:**
   ```bash
   cd ~/Documents
   ```

3. **Create the project structure:**
   ```bash
   mkdir -p tech4060-procedure/my-dev-environment/terraform
   ```

4. **Navigate into the terraform folder:**
   ```bash
   cd tech4060-procedure/my-dev-environment/terraform
   ```

5. **Verify you're in the correct location:**
   ```bash
   pwd
   ```
   - You should see: `/c/Users/YourName/Documents/tech4060-procedure/my-dev-environment/terraform`

---

### Step 5: Create Terraform Configuration Files

You'll create 4 files that define your infrastructure. Copy each file exactly as shown.

#### File 1: main.tf

This file defines what infrastructure to create (database, monitoring tools).

```bash
cat > main.tf << 'EOF'
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
EOF
```

#### File 2: variables.tf

This file defines configuration variables (database name, passwords, etc.).

```bash
cat > variables.tf << 'EOF'
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
EOF
```

#### File 3: outputs.tf

This file defines what information to display after deployment (URLs, connection info).

```bash
cat > outputs.tf << 'EOF'
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
EOF
```

#### File 4: prometheus.yml

This file configures Prometheus to collect metrics from the database.

```bash
cat > prometheus.yml << 'EOF'
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
EOF
```

#### File 5: .gitignore

This prevents sensitive files from being tracked in version control.

```bash
cat > .gitignore << 'EOF'
terraform.tfvars
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
postgres_data/
prometheus_data/
grafana_data/
EOF
```

---

### Step 6: Verify Files Were Created

```bash
ls -la
```

**You should see these 5 files:**
- main.tf
- variables.tf
- outputs.tf
- prometheus.yml
- .gitignore

If any are missing, go back and recreate them.

---

## Section 2: Deploy the Infrastructure

Now we'll use Terraform to deploy everything automatically.

### Step 7: Initialize Terraform

This downloads the Docker provider plugin.

```bash
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "~> 3.0"...
- Installing kreuzwerker/docker v3.0.2...

Terraform has been successfully initialized!
```

⏱️ **This takes 10-20 seconds**

---

### Step 8: Review the Deployment Plan

This shows what Terraform will create (without actually creating it).

```bash
terraform plan
```

**Expected output:**
```
Plan: 8 to add, 0 to change, 0 to destroy.
```

**What this means:**
- 4 Docker images will be downloaded
- 4 Docker containers will be created
- Nothing will be changed or destroyed (since this is the first run)

---

### Step 9: Deploy Everything

This command actually creates the infrastructure.

```bash
terraform apply
```

**What happens next:**
1. Terraform shows the plan again
2. You'll see: `Do you want to perform these actions?`
3. Type: **yes**
4. Press Enter

**Deployment process (3-5 minutes):**

You'll see:
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

**✅ Success looks like:**
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

database_endpoint = "localhost:5432"
database_name = "dev_db"
database_user = "dev_user"
grafana_url = "http://localhost:3000"
prometheus_url = "http://localhost:9090"
```

---

### Step 10: Verify Everything is Running

Check that all 4 containers are running:

```bash
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

✅ **All containers should show "Up"**

---

## Section 3: Create Sample Data

Before we can see anything in the monitoring dashboards, we need data in the database.

### Step 11: Create a Users Table

```bash
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT, email TEXT);"
```

**Expected output:** `CREATE TABLE`

---

### Step 12: Insert Sample Users

This adds 100 users to the database:

```bash
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "
INSERT INTO users (name, email)
SELECT 'User' || generate_series, 'user' || generate_series || '@example.com'
FROM generate_series(1, 100);
"
```

**Expected output:** `INSERT 0 100`

---

### Step 13: Verify Data Was Created

```bash
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "SELECT COUNT(*) FROM users;"
```

**Expected output:**
```
 count 
-------
   100
(1 row)
```

---

## Section 4: Set Up Grafana Dashboard

Now we'll create visual dashboards to monitor the database.

### Step 14: Access Grafana

1. Open your web browser
2. Go to: **http://localhost:3000**
3. Login with:
   - **Username:** admin
   - **Password:** admin123

You should see the Grafana home page.

---

### Step 15: Add Prometheus Data Source

Grafana needs to know where to get the metrics from.

1. Click **"Connections"** in the left sidebar
2. Click **"Data sources"**
3. Click **"Add data source"** (blue button)
4. Select **"Prometheus"**
5. In the **URL** field, enter: `http://host.docker.internal:9090`
6. Scroll to the bottom
7. Click **"Save & Test"**

✅ **You should see:** "Successfully queried the Prometheus API" (green checkmark)

---

### Step 16: Create Your First Dashboard

1. Click the **"+"** icon in the left sidebar
2. Select **"Create Dashboard"**
3. Click **"Add visualization"**
4. Select **"Prometheus"** as the data source

---

### Step 17: Create Panel 1 - Database Status

This panel shows if the database is running (green) or down (red).

1. **Panel title:** Click "Panel Title" at top, change to: `Database Status`
2. **Query:** In the query box at bottom, enter:
   ```
   pg_up
   ```
3. **Visualization type:** Click "Time series" dropdown, select **"Stat"**
4. **Color thresholds:** 
   - Click the "Thresholds" tab on right
   - Set: Red (0), Green (1)
5. Click **"Apply"** (top right)

**You should see a green "1" meaning database is UP!**

---

### Step 18: Create Panel 2 - Total Users

1. Click **"Add"** → **"Visualization"**
2. **Panel title:** `Total Users in Database`
3. **Query:**
   ```
   pg_stat_database_tup_inserted{datname="dev_db"}
   ```
4. **Visualization:** Stat
5. **Unit:** On right side, under "Standard options", set Unit to "short"
6. Click **"Apply"**

**You should see "158" or similar (the number of rows inserted)**

---

### Step 19: Create Panel 3 - Transaction Rate

This shows database activity as a graph over time.

1. Click **"Add"** → **"Visualization"**
2. **Panel title:** `Database Transaction Rate`
3. **Query:**
   ```
   rate(pg_stat_database_xact_commit{datname="dev_db"}[1m])
   ```
4. **Visualization:** Time series (default)
5. **Unit:** Set to "ops/sec"
6. Click **"Apply"**

**You should see a graph (may be flat if no activity recently)**

---

### Step 20: Create Panel 4 - Active Connections

1. Click **"Add"** → **"Visualization"**
2. **Panel title:** `Active Database Connections`
3. **Query:**
   ```
   pg_stat_database_numbackends{datname="dev_db"}
   ```
4. **Visualization:** Gauge
5. **Min:** 0, **Max:** 100
6. Click **"Apply"**

**You should see a gauge showing current connections (probably 2-5)**

---

### Step 21: Save Your Dashboard

1. Click the **disk icon** (top right) to save
2. **Name:** `Database Monitoring Dashboard`
3. Click **"Save"**

---

### Step 22: Configure Auto-Refresh

Make the dashboard update automatically:

1. In the top-right corner, click the **time range dropdown** (shows "Last 6 hours")
2. Change to: **"Last 5 minutes"**
3. Click the **refresh dropdown** (circular arrow icon)
4. Select: **"5s"** (refresh every 5 seconds)

**Now your dashboard will update automatically!**

---

## Section 5: Generate Live Activity

Let's create database activity to see the monitoring in action.

### Step 23: Insert Data in Real-Time

Run this command and watch your Grafana dashboard:

```bash
for i in {200..250}; do
    docker exec -it dev_postgres psql -U dev_user -d dev_db -c "INSERT INTO users (name, email) VALUES ('User$i', 'user$i@example.com');"
    echo "Inserted User$i - Check Grafana!"
    sleep 2
done
```

**What you should see:**
- The "Total Users" number increasing
- The "Transaction Rate" graph spiking
- Real-time updates every 5 seconds

🎉 **Congratulations! Your monitoring system is working!**

---

## Section 6: Understanding What You Built

### Infrastructure as Code Benefits

What you just did would traditionally require:
- Manual Docker installation
- Hand-typing docker run commands with 20+ parameters
- Manual configuration of Prometheus
- Manual setup of Grafana
- Hours of troubleshooting

**With Infrastructure as Code (Terraform), you did all of this with one command: `terraform apply`**

### Key Concepts Demonstrated

1. **Automation:** No manual clicking or configuration
2. **Reproducibility:** Anyone can run `terraform apply` and get identical results
3. **Version Control:** All configuration is in text files (can be tracked in Git)
4. **Documentation:** The Terraform files themselves document your infrastructure
5. **Observability:** Professional monitoring tools used by companies like Netflix, Uber, and Airbnb

---

## Section 7: Management Commands

### View Current Infrastructure

```bash
# See what Terraform is managing
terraform show

# See outputs (URLs, endpoints)
terraform output
```

### Stop Everything (But Keep Data)

```bash
# Stop all containers
docker stop dev_postgres postgres_exporter prometheus grafana
```

### Start Everything Again

```bash
# Start all containers
docker start dev_postgres postgres_exporter prometheus grafana
```

### Completely Remove Everything

```bash
terraform destroy
```

Type `yes` when prompted. This removes all containers and frees up disk space.

⚠️ **Warning:** This deletes all data. The local folders (postgres_data, prometheus_data, grafana_data) will remain and can be manually deleted.

---

## Troubleshooting

### Issue: "Cannot connect to Docker daemon"

**Problem:** Docker Desktop is not running  
**Solution:**
1. Open Docker Desktop from Start menu
2. Wait for green "Docker Desktop is running" message
3. Try the command again

### Issue: Port already in use

**Error:** `Bind for 0.0.0.0:5432 failed: port is already allocated`  
**Solution:**
1. Another program is using that port
2. Either stop the other program, or
3. Change the port in `variables.tf`:
   ```hcl
   variable "db_port" {
     default = 5433  # Changed from 5432
   }
   ```
4. Run `terraform apply` again

### Issue: Grafana shows "No Data"

**Solution:**
1. Wait 15-30 seconds for Prometheus to scrape first metrics
2. Check time range is set to "Last 5 minutes"
3. Verify Prometheus data source URL: `http://host.docker.internal:9090`
4. Click "Save & Test" on data source again

### Issue: Can't access Grafana at localhost:3000

**Solution:**
1. Check container is running: `docker ps | grep grafana`
2. If not running: `docker start grafana`
3. Wait 10 seconds and try again
4. Check firewall isn't blocking port 3000

---

## Cleanup Instructions

When you're done with the assignment:

### Option 1: Keep Everything for Later

Just close the terminal. Everything keeps running in the background.

To stop using system resources:
```bash
docker stop dev_postgres postgres_exporter prometheus grafana
```

### Option 2: Complete Removal

```bash
# Navigate to terraform folder
cd ~/Documents/tech4060-procedure/my-dev-environment/terraform

# Destroy infrastructure
terraform destroy

# Type 'yes' when prompted

# Manually delete data folders (optional)
rm -rf postgres_data prometheus_data grafana_data
```

---

## Summary

You have successfully:

✅ Installed Docker, Terraform, and Git  
✅ Created Infrastructure as Code files defining a complete monitoring stack  
✅ Deployed 4 containers (PostgreSQL, Prometheus, Grafana, Exporter) with one command  
✅ Created a database with sample data  
✅ Built visual dashboards showing real-time database metrics  
✅ Demonstrated professional DevOps observability practices  

**Key Achievement:** You've deployed production-grade monitoring infrastructure using the same tools and practices used by major tech companies.

---

## Additional Resources

- **Docker Documentation:** https://docs.docker.com/
- **Terraform Tutorial:** https://learn.hashicorp.com/terraform
- **Prometheus Documentation:** https://prometheus.io/docs/
- **Grafana Tutorials:** https://grafana.com/tutorials/
- **PostgreSQL Guide:** https://www.postgresql.org/docs/

---

**Document Version:** 1.0  
**Last Updated:** October 31, 2025  
**Tested On:** Windows 10/11 with Docker Desktop v24.x, Terraform v1.13.4
