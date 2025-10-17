#!/bin/bash

# User Data Script for EC2 Instances
# This script sets up the instance with necessary software and configurations

set -e

# Variables
ENVIRONMENT="${environment}"
APP_NAME="${app_name}"
LOG_FILE="/var/log/user-data.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "Starting user data script for $ENVIRONMENT-$APP_NAME"

# Update system packages
log "Updating system packages"
yum update -y

# Install required packages
log "Installing required packages"
yum install -y \
    awscli \
    htop \
    wget \
    curl \
    unzip \
    git \
    jq \
    amazon-cloudwatch-agent

# Install Docker (if needed)
if [ "$APP_NAME" = "web" ] || [ "$APP_NAME" = "app" ]; then
    log "Installing Docker"
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
fi

# Install Node.js (if needed)
if [ "$APP_NAME" = "web" ] || [ "$APP_NAME" = "app" ]; then
    log "Installing Node.js"
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs
fi

# Install Python 3 and pip (if needed)
if [ "$APP_NAME" = "app" ] || [ "$APP_NAME" = "worker" ]; then
    log "Installing Python 3"
    yum install -y python3 python3-pip
fi

# Configure CloudWatch Agent
log "Configuring CloudWatch Agent"
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/$ENVIRONMENT-$APP_NAME/system",
                        "log_stream_name": "{instance_id}/messages"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/$ENVIRONMENT-$APP_NAME/user-data",
                        "log_stream_name": "{instance_id}/user-data"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch Agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

# Create application directory
log "Creating application directory"
mkdir -p /opt/$APP_NAME
chown ec2-user:ec2-user /opt/$APP_NAME

# Create a simple health check script
log "Creating health check script"
cat > /opt/$APP_NAME/health-check.sh << 'EOF'
#!/bin/bash

# Simple health check script
# Returns 0 if healthy, 1 if unhealthy

# Check if the application is running
if [ "$APP_NAME" = "web" ]; then
    # Check if web server is running
    if systemctl is-active --quiet nginx || systemctl is-active --quiet httpd; then
        exit 0
    else
        exit 1
    fi
elif [ "$APP_NAME" = "app" ]; then
    # Check if application is running
    if pgrep -f "node" > /dev/null || pgrep -f "python" > /dev/null; then
        exit 0
    else
        exit 1
    fi
else
    # Default health check
    exit 0
fi
EOF

chmod +x /opt/$APP_NAME/health-check.sh

# Create a simple application based on the app name
if [ "$APP_NAME" = "web" ]; then
    log "Setting up web server"
    
    # Install Nginx
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create a simple HTML page
    cat > /usr/share/nginx/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>$ENVIRONMENT - $APP_NAME</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
        .status { color: green; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to $ENVIRONMENT Environment</h1>
            <h2>$APP_NAME Server</h2>
        </div>
        <div class="info">
            <p><strong>Environment:</strong> $ENVIRONMENT</p>
            <p><strong>Application:</strong> $APP_NAME</p>
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
            <p><strong>Status:</strong> <span class="status">Healthy</span></p>
        </div>
    </div>
</body>
</html>
EOF

elif [ "$APP_NAME" = "app" ]; then
    log "Setting up application server"
    
    # Create a simple Node.js application
    cat > /opt/$APP_NAME/app.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.json({
        message: 'Hello from the application server!',
        environment: process.env.ENVIRONMENT || 'unknown',
        app_name: process.env.APP_NAME || 'unknown',
        timestamp: new Date().toISOString(),
        instance_id: process.env.INSTANCE_ID || 'unknown'
    });
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

app.listen(port, () => {
    console.log(`Application server running on port ${port}`);
});
EOF

    # Create package.json
    cat > /opt/$APP_NAME/package.json << 'EOF'
{
    "name": "terraform-terragrunt-app",
    "version": "1.0.0",
    "description": "Sample application for Terraform Terragrunt project",
    "main": "app.js",
    "scripts": {
        "start": "node app.js"
    },
    "dependencies": {
        "express": "^4.18.2"
    }
}
EOF

    # Install dependencies and start the application
    cd /opt/$APP_NAME
    npm install
    npm start &
    
    # Create systemd service
    cat > /etc/systemd/system/$APP_NAME.service << EOF
[Unit]
Description=$APP_NAME Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/$APP_NAME
ExecStart=/usr/bin/node app.js
Restart=always
Environment=ENVIRONMENT=$ENVIRONMENT
Environment=APP_NAME=$APP_NAME
Environment=INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start $APP_NAME
    systemctl enable $APP_NAME

elif [ "$APP_NAME" = "worker" ]; then
    log "Setting up worker server"
    
    # Create a simple Python worker
    cat > /opt/$APP_NAME/worker.py << 'EOF'
import time
import os
import json
from datetime import datetime

def main():
    while True:
        print(f"Worker running at {datetime.now()}")
        print(f"Environment: {os.environ.get('ENVIRONMENT', 'unknown')}")
        print(f"App Name: {os.environ.get('APP_NAME', 'unknown')}")
        print(f"Instance ID: {os.environ.get('INSTANCE_ID', 'unknown')}")
        time.sleep(30)

if __name__ == "__main__":
    main()
EOF

    # Create systemd service
    cat > /etc/systemd/system/$APP_NAME.service << EOF
[Unit]
Description=$APP_NAME Worker
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/$APP_NAME
ExecStart=/usr/bin/python3 worker.py
Restart=always
Environment=ENVIRONMENT=$ENVIRONMENT
Environment=APP_NAME=$APP_NAME
Environment=INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start $APP_NAME
    systemctl enable $APP_NAME
fi

# Set up log rotation
log "Setting up log rotation"
cat > /etc/logrotate.d/$APP_NAME << EOF
/var/log/$APP_NAME/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ec2-user ec2-user
    postrotate
        systemctl reload $APP_NAME > /dev/null 2>&1 || true
    endscript
}
EOF

# Create monitoring script
log "Creating monitoring script"
cat > /opt/$APP_NAME/monitor.sh << 'EOF'
#!/bin/bash

# Simple monitoring script
LOG_FILE="/var/log/monitor.log"

while true; do
    echo "$(date): Checking system health" >> $LOG_FILE
    
    # Check disk space
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $DISK_USAGE -gt 80 ]; then
        echo "$(date): WARNING: Disk usage is ${DISK_USAGE}%" >> $LOG_FILE
    fi
    
    # Check memory usage
    MEM_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')
    if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
        echo "$(date): WARNING: Memory usage is ${MEM_USAGE}%" >> $LOG_FILE
    fi
    
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x /opt/$APP_NAME/monitor.sh

# Start monitoring script in background
nohup /opt/$APP_NAME/monitor.sh > /dev/null 2>&1 &

# Final setup
log "Finalizing setup"

# Create a completion marker
touch /opt/$APP_NAME/setup-complete

# Set proper permissions
chown -R ec2-user:ec2-user /opt/$APP_NAME

log "User data script completed successfully"

# Send completion notification to CloudWatch
aws logs create-log-group --log-group-name "/aws/ec2/$ENVIRONMENT-$APP_NAME/setup" --region us-east-1 || true
aws logs create-log-stream --log-group-name "/aws/ec2/$ENVIRONMENT-$APP_NAME/setup" --log-stream-name "$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" --region us-east-1 || true
aws logs put-log-events \
    --log-group-name "/aws/ec2/$ENVIRONMENT-$APP_NAME/setup" \
    --log-stream-name "$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" \
    --log-events timestamp=$(date +%s000),message="User data script completed successfully" \
    --region us-east-1 || true

log "Setup completed and logged to CloudWatch"
