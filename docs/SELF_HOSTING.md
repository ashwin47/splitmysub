# SplitMySub Self-Hosting Guide

A comprehensive guide for self-hosting your own instance of SplitMySub. This document covers everything from quick Docker setup to advanced security configurations and maintenance procedures.

## 🎯 Overview

SplitMySub is designed to be easily self-hosted with minimal configuration. Using SQLite as the database means no complex database server setup is required - just deploy and run!

**Key Benefits of Self-Hosting:**
- **Complete Control**: Own your data and infrastructure
- **Privacy**: No third-party data sharing
- **Customization**: Modify the application to fit your needs
- **Cost-Effective**: No subscription fees, just hosting costs

---

## 🚀 Quick Start (Docker - Recommended)

The fastest way to get SplitMySub running is with Docker.

### Prerequisites
- Docker and Docker Compose installed
- Domain name (optional, can use IP address)
- Basic understanding of environment variables

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/ashwin47/splitmysub.git
cd splitmysub

# Copy environment template
cp .env.example .env
```

### 2. Configure Environment Variables

Edit `.env` file with your settings:

```bash
# Required - App Configuration
APP_HOST=your-domain.com
APP_PROTOCOL=https
RAILS_MASTER_KEY=your-rails-master-key

# Required - Email Configuration (choose one)
RESEND_API_KEY=your-resend-api-key
# OR
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-smtp-password

# Optional - Admin Access
ADMIN_PASSWORD=your-secure-admin-password
```

### 3. Deploy with Docker Compose

```bash
# Build and start containers
docker-compose up -d

# Run database migrations
docker-compose exec web rails db:migrate

# Create admin user (optional)
docker-compose exec web rails runner "User.create!(email: 'admin@yourdomain.com', password: ENV['ADMIN_PASSWORD'])"
```

### 4. Access Your Instance

Visit `http://your-domain.com` or `http://your-server-ip:3000`

---

## 🔧 Manual Installation

For users who prefer manual installation or need custom configurations.

### System Requirements

- **Operating System**: Ubuntu 20.04+ (recommended), macOS, or Windows with WSL2
- **Ruby**: 3.4.4 (exact version required)
- **Node.js**: 20.18.1+
- **Yarn**: 1.22.x+
- **SQLite**: 3.x (usually pre-installed)
- **Git**: For cloning and updates

### Installation Steps

#### 1. Install Dependencies

**Ubuntu/Debian:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Ruby dependencies
sudo apt install -y curl gpg build-essential libssl-dev libreadline-dev zlib1g-dev

# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby 3.4.4
rbenv install 3.4.4
rbenv global 3.4.4

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install -y yarn
```

**macOS:**
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install ruby@3.4.4 node yarn sqlite3
```

#### 2. Clone and Setup Application

```bash
# Clone repository
git clone https://github.com/ashwin47/splitmysub.git
cd splitmysub

# Install Ruby gems
bundle install

# Install JavaScript packages
yarn install

# Setup environment
cp .env.example .env
# Edit .env with your configuration
```

#### 3. Database Setup

```bash
# Create and migrate database
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate

# Seed initial data (optional)
RAILS_ENV=production rails db:seed
```

#### 4. Asset Compilation

```bash
# Precompile assets for production
RAILS_ENV=production rails assets:precompile
```

#### 5. Start Application

```bash
# Start the Rails server
RAILS_ENV=production rails server -b 0.0.0.0 -p 3000
```

---

## 🔒 Security Configuration

### Environment Variables Security

**Never commit sensitive data to version control.** Use environment variables for all sensitive information:

```bash
# Required secrets
RAILS_MASTER_KEY=your-master-key-here
RESEND_API_KEY=your-resend-api-key
ADMIN_PASSWORD=your-secure-password

# Optional secrets
SMTP_PASSWORD=your-smtp-password
SECRET_KEY_BASE=your-secret-key-base
```

### SSL/TLS Configuration

#### With Reverse Proxy (Nginx - Recommended)

```nginx
# /etc/nginx/sites-available/splitmysub
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;

    # SSL Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### With Let's Encrypt (Certbot)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal (add to crontab)
0 12 * * * /usr/bin/certbot renew --quiet
```

### Firewall Configuration

```bash
# Configure UFW (Ubuntu)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Application Security

#### Content Security Policy

The application includes CSP headers. Configure in `config/initializers/content_security_policy.rb`:

```ruby
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.script_src  :self, :https
  policy.style_src   :self, :https, :unsafe_inline
  policy.img_src     :self, :https, :data
  policy.font_src    :self, :https, :data
  policy.connect_src :self, :https
  policy.object_src  :none
  policy.base_uri    :self
  policy.form_action :self
end
```

#### Rate Limiting

SplitMySub uses Rails 8 native rate limiting, configured automatically:

```ruby
# Example rate limiting in controllers
rate_limit to: 10, within: 3.minutes, only: :magic_link, 
           with: -> { redirect_to new_session_url, alert: "Try again later." }

# Rate limiting for invitations
rate_limit to: 5, within: 1.hour, only: [:create, :send_email],
           with: -> { redirect_to @invitation, alert: "Too many attempts. Try again later." }
```

---

## 📧 Email Configuration

### Resend API (Recommended)

```bash
# Environment variables
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx
RESEND_SENDER_DOMAIN=yourdomain.com
```

### SMTP Configuration

Choose from these popular providers:

#### Gmail (Personal Use)
```bash
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-16-character-app-password
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
```

#### SendGrid (Production)
```bash
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
```

#### Mailgun (Production)
```bash
SMTP_USERNAME=your-mailgun-smtp-username
SMTP_PASSWORD=your-mailgun-smtp-password
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
```

### Email Testing

```bash
# Test email configuration
docker-compose exec web rails runner "TestMailer.test_email('your-email@example.com').deliver_now"

# Or for manual installation
RAILS_ENV=production rails runner "TestMailer.test_email('your-email@example.com').deliver_now"
```

---

## 🔔 Automated Reminder System

### How Reminders Work (No Cron Required!)

SplitMySub uses **SolidQueue** with recurring jobs instead of traditional cron jobs. This is perfect for containerized deployments and requires **zero additional configuration**.

#### Automatic Scheduling

The following jobs run automatically every day:

```yaml
# Daily at 9 AM - Send payment reminders
daily_reminder_processor:
  class: DailyReminderProcessorJob
  schedule: every day at 9am

# Daily at 1 AM - Generate new billing cycles  
billing_cycle_generator:
  class: BillingCycleGeneratorJob
  schedule: every day at 1am

# Daily at 2 AM - Archive old billing cycles
billing_cycle_archiver:
  class: BillingCycleArchiverJob
  schedule: every day at 2am
```

#### How It Works

1. **SolidQueue** runs inside your Rails app (no separate process needed)
2. **Recurring jobs** are configured in `config/recurring.yml`
3. **Background processing** handles email and Telegram notifications
4. **Automatic retries** for failed jobs
5. **Job monitoring** via SolidQueue dashboard

#### Manual Reminder Testing

```bash
# Test reminder system
docker-compose exec web rails reminders:test[PROJECT_ID]

# Process reminders manually
docker-compose exec web rails reminders:process

# View reminder statistics
docker-compose exec web rails reminders:stats

# Schedule next reminder batch
docker-compose exec web rails reminders:schedule_daily
```

#### Reminder Types

- **Gentle Reminder**: 7 days before due date
- **Standard Reminder**: 3 days before due date  
- **Urgent Reminder**: 1 day before due date
- **Final Notice**: On due date
- **Overdue Notice**: 3 days after due date

#### Notification Methods

- **Email**: Always sent (if email configured)
- **Telegram**: Sent if user has linked Telegram account
- **Dashboard Indicators**: Overdue/due soon payments visible on dashboard and upcoming payments page

---

## 🔄 Maintenance and Updates

### Regular Maintenance Tasks

#### Daily Automated Tasks

Create `/usr/local/bin/splitmysub_daily.sh`:

```bash
#!/bin/bash
set -e

echo "Starting daily maintenance for SplitMySub..."

# Backup database
docker run --rm \
  -v splitmysub_db:/db:ro \
  -v splitmysub_storage:/storage:ro \
  -v /var/backups/splitmysub:/backup \
  alpine \
  tar czf /backup/splitmysub_backup_$(date +%Y%m%d).tar.gz -C / db storage

# Clean old backups (keep 30 days)
find /var/backups/splitmysub -name "*.tar.gz" -mtime +30 -delete

# Clean old logs
docker-compose exec web rails log:clear

# Optimize SQLite database
docker-compose exec web rails runner "ActiveRecord::Base.connection.execute('VACUUM;')"

echo "Daily maintenance completed!"
```

#### Weekly Tasks

```bash
#!/bin/bash
# /usr/local/bin/splitmysub_weekly.sh

# Update system packages
sudo apt update && sudo apt upgrade -y

# Restart containers to apply any updates
docker-compose restart

# Check disk usage
df -h

# Check memory usage
free -h

echo "Weekly maintenance completed!"
```

#### Setup Cron Jobs

```bash
# Add to crontab
sudo crontab -e

# Daily maintenance at 2 AM
0 2 * * * /usr/local/bin/splitmysub_daily.sh

# Weekly maintenance on Sunday at 3 AM
0 3 * * 0 /usr/local/bin/splitmysub_weekly.sh
```

### Application Updates

#### Docker Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild containers
docker-compose build --no-cache

# Update with zero downtime
docker-compose up -d

# Run migrations
docker-compose exec web rails db:migrate

# Restart if needed
docker-compose restart web
```

#### Manual Updates

```bash
# Pull latest changes
git pull origin main

# Update dependencies
bundle install
yarn install

# Run migrations
RAILS_ENV=production rails db:migrate

# Recompile assets
RAILS_ENV=production rails assets:precompile

# Restart application
sudo systemctl restart splitmysub  # or your process manager
```

### Database Maintenance

#### SQLite Optimization

```bash
# Vacuum database (reclaim space)
docker-compose exec web rails runner "ActiveRecord::Base.connection.execute('VACUUM;')"

# Analyze database (update statistics)
docker-compose exec web rails runner "ActiveRecord::Base.connection.execute('ANALYZE;')"

# Check database integrity
docker-compose exec web rails runner "ActiveRecord::Base.connection.execute('PRAGMA integrity_check;')"
```

#### Database Backups

```bash
# Create backup
docker run --rm \
  -v splitmysub_db:/db:ro \
  -v $(pwd):/backup \
  alpine \
  tar czf /backup/splitmysub_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C / db

# Restore backup
docker-compose stop
docker run --rm \
  -v splitmysub_db:/db \
  -v $(pwd):/backup \
  alpine \
  tar xzf /backup/splitmysub_backup_TIMESTAMP.tar.gz -C /
docker-compose start
```

---

## 🔍 Monitoring and Logging

### Application Monitoring

#### Health Check Endpoint

SplitMySub includes a health check endpoint at `/up`:

```bash
# Check application health
curl https://your-domain.com/up

# Expected response: HTTP 200 with status information
```

#### Log Monitoring

```bash
# View application logs
docker-compose logs -f web

# View specific log files
docker-compose exec web tail -f log/production.log

# Search logs for errors
docker-compose exec web grep -i error log/production.log
```

#### System Monitoring

Create a simple monitoring script:

```bash
#!/bin/bash
# /usr/local/bin/monitor_splitmysub.sh

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo "ERROR: SplitMySub containers are not running!"
    docker-compose up -d
fi

# Check disk usage
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "WARNING: Disk usage is ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ $MEMORY_USAGE -gt 80 ]; then
    echo "WARNING: Memory usage is ${MEMORY_USAGE}%"
fi

# Check application health
if ! curl -s https://your-domain.com/up > /dev/null; then
    echo "ERROR: Application health check failed!"
    docker-compose restart web
fi
```

### Performance Monitoring

#### SQLite Performance

```bash
# Check database size
docker-compose exec web ls -lah db/

# Check query performance
docker-compose exec web rails runner "
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::DEBUG
  # Run your queries here
"
```

#### Application Performance

```bash
# Monitor Rails performance
docker-compose exec web rails runner "
  puts 'Memory usage: #{(Process.memory_usage[:rss] / 1024.0 / 1024.0).round(2)} MB'
  puts 'Database connections: #{ActiveRecord::Base.connection_pool.stat}'
"
```

---

## 🛠️ Troubleshooting

### Common Issues

#### Database Issues

**Problem**: Database is locked
```
SQLite3::BusyException: database is locked
```

**Solution**:
```bash
# Check for long-running processes
docker-compose exec web rails runner "puts ActiveRecord::Base.connection.execute('PRAGMA compile_options;')"

# Increase timeout in database.yml
# timeout: 30000  # 30 seconds
```

**Problem**: Database corruption
```
SQLite3::CorruptException: database disk image is malformed
```

**Solution**:
```bash
# Restore from backup
docker-compose stop
# Restore backup (see backup section)
docker-compose start

# If no backup, try to recover
docker-compose exec web sqlite3 db/production.sqlite3 '.recover' | sqlite3 db/recovered.sqlite3
```

#### Application Issues

**Problem**: Assets not loading
```
ActionView::Template::Error: Asset not found
```

**Solution**:
```bash
# Recompile assets
docker-compose exec web rails assets:precompile

# Clear cache
docker-compose exec web rails tmp:clear
```

**Problem**: Memory issues
```
Killed (signal 9)
```

**Solution**:
```bash
# Check memory usage
free -h

# Increase swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Add to /etc/fstab for persistence
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

#### Email Issues

**Problem**: Emails not sending
```
Net::SMTPAuthenticationError: Authentication failed
```

**Solution**:
```bash
# Test email configuration
docker-compose exec web rails runner "
  puts 'SMTP settings:'
  puts ActionMailer::Base.smtp_settings.inspect
  
  # Test connection
  smtp = Net::SMTP.new('smtp.gmail.com', 587)
  smtp.enable_starttls
  smtp.start('localhost', ENV['SMTP_USERNAME'], ENV['SMTP_PASSWORD'], :plain)
  puts 'SMTP connection successful!'
  smtp.finish
"
```

#### SSL/TLS Issues

**Problem**: SSL certificate errors
```
OpenSSL::SSL::SSLError: certificate verify failed
```

**Solution**:
```bash
# Check certificate validity
openssl x509 -in /path/to/certificate.crt -text -noout

# Renew Let's Encrypt certificate
sudo certbot renew --force-renewal
```

### Debug Mode

Enable debug mode for troubleshooting:

```bash
# Set environment variable
export RAILS_LOG_LEVEL=debug

# Or in .env file
RAILS_LOG_LEVEL=debug

# Restart application
docker-compose restart web
```

### Getting Help

If you encounter issues not covered here:

1. **Check the logs**: `docker-compose logs -f web`
2. **Search GitHub issues**: Look for similar problems in the repository
3. **Create an issue**: Include logs, configuration, and steps to reproduce
4. **Community support**: Join our Discord/Slack for real-time help

---

## 📈 Scaling Considerations

### When to Scale

Consider scaling when you experience:
- Response times > 2 seconds
- Database queries > 1000ms
- Memory usage consistently > 80%
- More than 100 concurrent users

### Horizontal Scaling

#### Load Balancer Setup

```nginx
# /etc/nginx/sites-available/splitmysub-lb
upstream splitmysub_backend {
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
    server 127.0.0.1:3002;
}

server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://splitmysub_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Multiple App Instances

```yaml
# docker-compose.scale.yml
version: '3.8'
services:
  web:
    build: .
    environment:
      - RAILS_ENV=production
    volumes:
      - shared_db:/rails/db
      - shared_storage:/rails/storage
    ports:
      - "3000-3002:3000"
    deploy:
      replicas: 3

volumes:
  shared_db:
  shared_storage:
```

### Database Scaling

#### SQLite Limitations

SQLite is excellent for small to medium applications but has limitations:
- **Concurrent writes**: Limited to one writer at a time
- **Database size**: Recommended maximum ~1TB
- **Network access**: File-based, not network accessible

#### Migration to PostgreSQL

When SQLite becomes a bottleneck:

```bash
# 1. Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# 2. Create database and user
sudo -u postgres createdb splitmysub_production
sudo -u postgres createuser -s splitmysub

# 3. Export SQLite data
sqlite3 db/production.sqlite3 .dump > splitmysub_dump.sql

# 4. Convert and import to PostgreSQL
# (Use tools like sqlite3-to-postgresql)

# 5. Update database.yml
# production:
#   adapter: postgresql
#   database: splitmysub_production
#   username: splitmysub
#   password: <%= ENV['DATABASE_PASSWORD'] %>
#   host: localhost
```

---

## 🎯 Best Practices Summary

### Security
- ✅ Use HTTPS in production
- ✅ Keep secrets in environment variables
- ✅ Enable rate limiting
- ✅ Regular security updates
- ✅ Implement proper firewall rules

### Performance
- ✅ Regular database maintenance
- ✅ Monitor resource usage
- ✅ Implement caching strategies
- ✅ Optimize database queries
- ✅ Use CDN for static assets

### Maintenance
- ✅ Automated backups
- ✅ Regular updates
- ✅ Log monitoring
- ✅ Health checks
- ✅ Documentation updates

### Monitoring
- ✅ Application health checks
- ✅ Resource monitoring
- ✅ Error tracking
- ✅ Performance metrics
- ✅ Backup verification

---

## 📚 Additional Resources

- **Docker Documentation**: https://docs.docker.com/
- **Rails Deployment Guide**: https://guides.rubyonrails.org/deployment.html
- **SQLite Documentation**: https://sqlite.org/docs.html
- **Nginx Configuration**: https://nginx.org/en/docs/
- **Let's Encrypt**: https://letsencrypt.org/getting-started/

---

**Need help?** Check our [GitHub Issues](https://github.com/yourusername/splitmysub/issues) or join our community for support! 