# Linux Commands Reference Guide
## Extracted, Organized, and Explained

---

## Table of Contents
1. [Beginner Level Commands](#beginner-level-commands)
2. [Intermediate Level Commands](#intermediate-level-commands)
3. [Advanced Level Commands](#advanced-level-commands)
4. [Expert Level Commands](#expert-level-commands)

---

## Beginner Level Commands

### 1. `pwd` - Print Working Directory
Shows your current directory location.

```bash
pwd
# Output: /home/username/projects
```

**Use Cases:**
- Check where you are in the filesystem
- Verify you're in the correct directory before running commands

---

### 2. `ls` - List Directory Contents
Lists files and directories in the current location.

```bash
# Basic listing
ls

# Long format with details
ls -l

# Show hidden files (starting with .)
ls -la

# Human-readable file sizes
ls -lh

# Count files in directory
ls -la | grep "^-" | wc -l
```

**Use Cases:**
- View files and folders
- Check file permissions and sizes
- Verify file existence

---

### 3. `cd` - Change Directory
Navigate between directories.

```bash
# Go to specific directory
cd /var/log

# Go to home directory
cd ~

# Go to parent directory
cd ..

# Go to previous directory
cd -
```

**Use Cases:**
- Navigate filesystem
- Access different project folders
- Move between system directories

---

### 4. `cat` - Concatenate and Display Files
Display file contents or combine multiple files.

```bash
# Display file content
cat filename.txt

# Display with line numbers
cat -n filename.txt

# View system information
cat /etc/os-release
cat /etc/passwd
```

**Use Cases:**
- View configuration files
- Check log file contents
- Display user accounts

---

### 5. `touch` - Create Empty Files
Creates new empty files or updates timestamps.

```bash
# Create single file
touch newfile.txt

# Create multiple files
touch file1.txt file2.txt file3.txt

# Create PID file
touch zabbix_proxy.pid
```

**Use Cases:**
- Create placeholder files
- Update file modification times
- Create lock/PID files for processes

---

### 6. `mkdir` - Make Directory
Creates new directories.

```bash
# Create single directory
mkdir projects

# Create nested directories
mkdir -p projects/backend/src/controllers
```

**Use Cases:**
- Organize files into folders
- Create project structures
- Set up application directories

---

### 7. `cp` - Copy Files and Directories
Copies files or directories from one location to another.

```bash
# Copy single file
cp source.txt destination.txt

# Copy multiple files with wildcard
cp file*.log /backup/

# Copy directory recursively
cp -r source_folder/ destination_folder/

# Force overwrite without prompts
yes | /bin/cp -rf * /var/www/html/

# Copy and preserve permissions
cp -p file.txt backup.txt
```

**Use Cases:**
- Backup files
- Deploy applications
- Duplicate configurations

---

### 8. `mv` - Move or Rename Files
Moves files/directories or renames them.

```bash
# Rename file
mv oldname.txt newname.txt

# Move file to different directory
mv file.txt /home/user/documents/

# Rename directory
mv old_folder/ new_folder/
```

**Use Cases:**
- Reorganize files
- Rename logs or backups
- Move files between locations

---

### 9. `rm` - Remove Files
Deletes files and directories.

```bash
# Remove single file
rm file.txt

# Remove directory recursively
rm -r folder/

# Force remove without confirmation
rm -rf folder/

# Remove using AWS S3 command
aws s3 rm s3://bucket-name/ --recursive --exclude "keep/*"
```

**Use Cases:**
- Clean up old files
- Remove temporary data
- Delete backups or logs

---

### 10. `echo` - Display Text or Variables
Prints text or variable values to terminal.

```bash
# Print text
echo "Hello World"

# Print variable
HOSTNAME="server-01"
echo "${HOSTNAME}"

# Append to file
echo "New line" >> file.txt

# Clear/empty a file
echo -n > /path/to/logfile.log

# Write to system files
echo 1 > /proc/sys/vm/drop_caches
```

**Use Cases:**
- Display messages
- Append to log files
- Clear log files
- Set system parameters

---

### 11. `truncate` - Shrink or Extend File Size
Changes file size, often used to clear logs.

```bash
# Clear/empty a log file
truncate -s 0 /var/log/application.log

# Set specific size
truncate -s 1M file.txt
```

**Use Cases:**
- Clear large log files without deleting them
- Free up disk space
- Reset log files while keeping file structure

---

### 12. `history` - Command History
Shows previously executed commands.

```bash
# Show command history
history

# Show recent 20 commands
history | tail -20

# Search history
history | grep ssh
history | grep gen
```

**Use Cases:**
- Find previously used commands
- Review what was executed
- Troubleshoot command syntax

---

## Intermediate Level Commands

### 13. `grep` - Search Text Patterns
Searches for patterns in files or output.

```bash
# Basic search
grep "error" /var/log/syslog

# Case-insensitive search
grep -i "error" logfile.txt

# Recursive search in directories
grep -r "TODO" /home/user/projects/
grep -ri "search_term" .

# Invert match (exclude lines)
grep -v "info" /var/log/app.log

# Search with extended regex
grep -RE "pattern1|pattern2|pattern3" /etc/

# Search and show line numbers
grep -n "function" app.js

# Search in specific files
grep -i -e "unix" -e "linux" script.sh

# Remove empty lines and comments
grep -v -e '^#' -e '^$' /etc/config.conf

# Search inside file from cloning logs
grep -i "Cloning into" /root/scripts/backup.log
```

**Use Cases:**
- Find errors in logs
- Search configuration files
- Filter command output
- Code searches

---

### 14. `find` - Search for Files and Directories
Locates files based on various criteria.

```bash
# Find by name
find /var/log -name "*.log"

# Find by type (f=file, d=directory)
find /home -type f -size +100M

# Find and execute command on results
find . -name "*.txt" -print0 | xargs -0 tail -n 2

# Find shell scripts in multiple directories
find /home/user/ /root/ -name "*.sh" -print0

# Find specific file across system
sudo find / -type f -name "index.html"
sudo find /var/www -type f -name "index.html"

# Find files modified in last 7 days
find /var/log -type f -mtime -7
```

**Use Cases:**
- Locate configuration files
- Find large files consuming disk space
- Search for specific file types
- Execute batch operations on files

---

### 15. `tail` - Display End of Files
Shows last lines of a file, useful for log monitoring.

```bash
# Show last 10 lines (default)
tail filename.txt

# Show last N lines
tail -n 50 /var/log/syslog

# Follow file in real-time (for logs)
tail -f /var/log/application.log

# Show last 2 lines from multiple files
tail -2 /home/user/logs/*.txt | grep 'Item'

# Multiple directories
find /path/dir1 /path/dir2 -name '*.txt' -print0 | xargs -0 tail -n 2
```

**Use Cases:**
- Monitor log files in real-time
- Check recent log entries
- Troubleshoot application issues
- Watch file changes

---

### 16. `du` - Disk Usage
Reports disk space used by files and directories.

```bash
# Summarize directory size
du -sh /var/log

# List all subdirectories with sizes
du -sh /*

# Human-readable format
du -h /home/user/

# Sort by size (largest first)
du -sh * 2>/dev/null | sort -rh | head -n 10
```

**Use Cases:**
- Find large directories
- Monitor disk space usage
- Identify storage hogs
- Cleanup planning

---

### 17. `tar` - Archive and Compress Files
Creates and extracts compressed archive files.

```bash
# Create compressed archive
tar -cvzf backup.tar.gz /path/to/directory

# Create archive of multiple files with wildcard
tar -cvzf logs.tar.gz *.log

# Create archive with timestamp
tar -cvzf backup-$(date +%Y%m%d).tar.gz /data

# Extract archive
tar -xvzf backup.tar.gz

# Extract to specific directory
tar -xvzf archive.tar.gz -C /destination/path/

# Archive all files in current directory
tar -cvzf archive.tar.gz *
```

**Options:**
- `-c` = create
- `-x` = extract
- `-v` = verbose
- `-z` = gzip compression
- `-f` = file name

**Use Cases:**
- Backup files and directories
- Transfer multiple files as one
- Compress logs
- Deploy applications

---

### 18. `chmod` - Change File Permissions
Modifies file and directory permissions.

```bash
# Numeric notation (rwx = 421)
chmod 755 script.sh     # rwxr-xr-x
chmod 644 file.txt      # rw-r--r--
chmod 775 directory/    # rwxrwxr-x

# Make script executable
chmod +x script.sh
chmod +x /tmp/file.pid

# Remove write permission
chmod -w file.txt

# Recursive permission change
chmod -R 755 /var/www/html/
```

**Common Permissions:**
- `755` = Owner: rwx, Group: r-x, Others: r-x (scripts, directories)
- `644` = Owner: rw-, Group: r--, Others: r-- (regular files)
- `600` = Owner: rw-, Group: ---, Others: --- (private files, SSH keys)
- `775` = Owner: rwx, Group: rwx, Others: r-x (shared directories)

**Use Cases:**
- Make scripts executable
- Secure sensitive files
- Set web directory permissions
- Configure SSH key permissions

---

### 19. `chown` - Change File Ownership
Changes owner and group of files/directories.

```bash
# Change owner and group
chown user:group file.txt

# Change ownership of directory recursively
chown -R user:group /path/to/directory/

# Change only owner
chown username file.txt

# Examples
chown -R www-data:www-data /var/www/html/
chown zabbix:zabbix zabbix_proxy.pid
sudo chown -R zabbix:zabbix /var/log/zabbix/
```

**Use Cases:**
- Fix file ownership issues
- Prepare files for specific services
- Configure application directories
- Set web server file ownership

---

### 20. `usermod` - Modify User Account
Modifies user account properties.

```bash
# Add user to group
usermod -aG groupname username

# Change user shell
usermod -s /bin/bash username

# Example: Add to wheel/sudo group
usermod -aG sudo username
```

**Use Cases:**
- Grant user additional group permissions
- Change login shell
- Manage user access rights

---

### 21. `setfacl` - Set File Access Control Lists
Provides fine-grained permission control beyond basic chmod.

```bash
# Grant read permission to specific user
setfacl -m u:jenkins:r /path/to/file.pem

# Grant full permissions
setfacl -m u:username:rwx /path/to/directory

# Remove ACL
setfacl -x u:username /path/to/file
```

**Use Cases:**
- Grant specific user access without changing group
- Fine-tune permissions for automation users
- Allow service accounts to access files

---

### 22. `ps` - Process Status
Displays information about running processes.

```bash
# Show all processes
ps aux

# Filter specific process
ps aux | grep nginx
ps aux | grep -i "service_name"

# Format with awk (memory usage)
ps aux | awk '{printf "%8.3f MB\t\t%s\n", $6/1024, $11}' | sort -n
```

**Use Cases:**
- Monitor running processes
- Find process IDs (PIDs)
- Check resource usage
- Troubleshoot hung processes

---

### 23. `systemctl` - System Service Manager
Controls systemd services and units.

```bash
# Start service
sudo systemctl start nginx

# Stop service
sudo systemctl stop nginx

# Restart service
sudo systemctl restart nginx

# Reload configuration
sudo systemctl reload nginx

# Enable service at boot
sudo systemctl enable nginx

# Disable service at boot
sudo systemctl disable nginx

# Check service status
sudo systemctl status nginx

# List all services
systemctl list-units --type=service

# List running services
systemctl list-units --type=service --state=running

# List active services
systemctl list-units --type=service --state=active

# Reload systemd manager configuration
sudo systemctl daemon-reload
```

**Use Cases:**
- Manage web servers, databases
- Control application services
- Configure startup services
- Troubleshoot service failures

---

### 24. `service` - Service Control (Legacy)
Older method to control services (still used in some systems).

```bash
# Check all running services
service --status-all | grep running

# Reload service
sudo service service_name reload
sudo service httpd reload
```

**Use Cases:**
- Manage services on older systems
- Check service status
- Restart services

---

### 25. `chkconfig` - Service Configuration Tool
Manages service startup settings (older systems).

```bash
# List services enabled at runlevel 3
chkconfig --list | grep '3:on'
```

**Use Cases:**
- Configure services on CentOS/RHEL 6 and older
- Check startup configuration

---

### 26. `netstat` - Network Statistics
Displays network connections and routing tables.

```bash
# Show listening ports and programs
sudo netstat -tulpn

# Filter specific port
sudo netstat -tulpn | grep 3000

# Find which service is listening
netstat -ltup | grep zabbix_agentd
```

**Options:**
- `-t` = TCP connections
- `-u` = UDP connections
- `-l` = Listening sockets
- `-p` = Show program names
- `-n` = Show numerical addresses

**Use Cases:**
- Check which ports are open
- Find port conflicts
- Verify service is listening
- Network troubleshooting

---

### 27. `ss` - Socket Statistics
Modern replacement for netstat.

```bash
# Show all listening TCP and UDP sockets
sudo ss -tulpn

# Filter by port
sudo ss -tulpn | grep :3000

# Show listening services
sudo ss -tulpn
```

**Use Cases:**
- Check port availability
- Monitor network connections
- Faster than netstat
- Troubleshoot network services

---

### 28. `nc` - Netcat (Network Testing)
Tests network connectivity and port availability.

```bash
# Test if port is open
nc -zv 10.20.30.40 10051

# Test web server
nc -zv example.com 80
nc -zv example.com 443
```

**Options:**
- `-z` = Scan without sending data
- `-v` = Verbose output

**Use Cases:**
- Test if remote port is accessible
- Verify firewall rules
- Check service availability
- Network troubleshooting

---

### 29. `firewall-cmd` - Firewall Management
Manages firewalld firewall rules (RHEL/CentOS).

```bash
# List all rules
firewall-cmd --list-all

# Add port permanently
firewall-cmd --add-port=10050/tcp --permanent

# Reload firewall
firewall-cmd --reload

# Remove port
firewall-cmd --remove-port=10050/tcp --permanent
```

**Use Cases:**
- Open ports for services
- Configure firewall rules
- Allow network access
- Secure server

---

### 30. `iptables` - IP Tables Firewall
Low-level firewall rule configuration.

```bash
# Allow incoming connection from specific IP
iptables -A INPUT -s 10.20.30.40/32 -p tcp --dport 10050 -j ACCEPT

# Allow outbound to specific domain
sudo iptables -A OUTPUT -p tcp --dport 80 -d mirrorlist.centos.org -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -d mirrorlist.centos.org -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

**Use Cases:**
- Fine-grained firewall control
- Network security hardening
- Port forwarding
- NAT configuration

---

### 31. `lsblk` - List Block Devices
Lists information about block devices (disks, partitions).

```bash
# List all block devices
lsblk

# Show filesystem info
lsblk -f
```

**Use Cases:**
- View disk partitions
- Check mounted filesystems
- Identify storage devices
- Plan disk operations

---

### 32. `df` - Disk Filesystem Usage
Reports filesystem disk space usage.

```bash
# Show all filesystems
df

# Human-readable format
df -h

# Show specific filesystem
df -h /var
```

**Use Cases:**
- Check available disk space
- Monitor storage capacity
- Troubleshoot full disk issues
- Plan storage needs

---

## Advanced Level Commands

### 33. `awk` - Text Processing Language
Powerful text processing and data extraction tool.

```bash
# Print specific columns
ps aux | awk '{print $1, $11}'

# Format output with calculations
ps aux | awk '{printf "%8.3f MB\t\t%s\n", $6/1024, $11}' | sort -n

# Print with formatted MB calculation
ps aux | awk '{print $6/1024 " MB\t\t" $11}' | sort -n

# Use custom field separator
awk -F ',' '{print $1, $3}' data.csv

# Filter with conditions
awk '$3 > 50' data.txt

# Search and extract from yum output
grep "$(yum updateinfo list security installed | tail -n +3 | head -n -1 | awk '{print $3}')" <(rpm -qa --last)
```

**Use Cases:**
- Parse log files
- Extract specific columns from output
- Calculate values from data
- Format reports

---

### 34. `sed` - Stream Editor
Performs text transformations on streams.

```bash
# Replace text (first occurrence)
sed 's/old/new/' file.txt

# Replace all occurrences
sed 's/old/new/g' file.txt

# Edit file in-place
sed -i 's/old/new/g' file.txt

# Delete lines matching pattern
sed '/pattern/d' file.txt

# Delete specific line numbers
sed '5d' file.txt
```

**Use Cases:**
- Find and replace in files
- Filter text streams
- Transform configuration files
- Automate text editing

---

### 35. `xargs` - Build and Execute Commands
Converts standard input into command arguments.

```bash
# Find and process files
find . -name "*.txt" -print0 | xargs -0 tail -n 2

# Find files and grep within them
find /path -name "*.log" -print0 | xargs -0 grep "error"

# Process with null-terminated strings (handles spaces in filenames)
find . -name "*.sh" -print0 | xargs -0 chmod +x
```

**Options:**
- `-0` = Use null character as delimiter (handles spaces in filenames)
- `-n` = Max arguments per command
- `-P` = Run in parallel

**Use Cases:**
- Process multiple files
- Batch operations
- Pipe output to commands
- Parallel execution

---

### 36. `sort` - Sort Lines of Text
Sorts lines in text files or output.

```bash
# Basic sort
sort file.txt

# Reverse sort
sort -r file.txt

# Numeric sort
sort -n numbers.txt

# Human-readable numeric sort (KB, MB, GB)
du -sh * | sort -rh

# Sort by specific column
sort -k 3 -n data.txt

# Sort with pipe
ps aux | sort -nrk 3,3 | head -n 10
```

**Use Cases:**
- Organize data
- Find largest/smallest values
- Order log entries
- Prepare data for analysis

---

### 37. `tr` - Translate or Delete Characters
Transforms or removes characters from input.

```bash
# Remove carriage returns (Windows to Unix)
tr -d '\r' < windows_file.sh > unix_file.sh

# Convert to uppercase
echo "hello" | tr '[:lower:]' '[:upper:]'

# Remove newlines
echo "line1\nline2" | tr -d '\n'

# Replace characters
echo "hello world" | tr ' ' '_'
```

**Use Cases:**
- Convert file formats (DOS to Unix)
- Text transformation
- Remove unwanted characters
- Case conversion

---

### 38. `sync` - Synchronize Cached Writes
Flushes filesystem buffers to disk.

```bash
# Sync filesystem
sync

# Clear page cache
sync && echo 1 > /proc/sys/vm/drop_caches

# Clear dentries and inodes
sync && echo 2 > /proc/sys/vm/drop_caches

# Clear all caches
sync && echo 3 > /proc/sys/vm/drop_caches
```

**Cache Types:**
- `1` = Page cache
- `2` = Dentries and inodes
- `3` = All caches

**Use Cases:**
- Free up memory
- Clear file system cache
- Performance testing
- Troubleshoot memory issues

---

### 39. `sysctl` - Configure Kernel Parameters
Modifies kernel parameters at runtime.

```bash
# View parameter
sysctl net.ipv4.ip_forward

# Set parameter temporarily
sudo sysctl -w net.ipv4.ip_forward=1

# Disable IPv6
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1

# Apply settings from file
sudo sysctl -p

# View all parameters
sysctl -a
```

**Use Cases:**
- Enable IP forwarding
- Tune network parameters
- Adjust kernel behavior
- Performance optimization

---

### 40. `crontab` - Schedule Tasks
Manages scheduled tasks (cron jobs).

```bash
# Edit crontab
crontab -e
sudo crontab -e

# List cron jobs
crontab -l

# Common schedule examples:
# Run at boot
@reboot /usr/sbin/service start

# Run at specific times
0 0,14,16,18 * * * /path/to/script.sh

# Daily at midnight
0 0 * * * /backup.sh

# Every hour
0 * * * * /monitor.sh
```

**Cron Format:**
```
* * * * * command
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, Sunday=0 or 7)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

**Use Cases:**
- Automated backups
- Scheduled maintenance
- Regular monitoring
- Periodic cleanups

---

### 41. `nohup` - Run Command Immune to Hangups
Runs commands that continue after logout.

```bash
# Run script in background
nohup /path/to/script.sh >> /var/log/script.log &

# Run Python script
nohup python script.py >> output.log &

# Multiple background tasks
nohup /root/backup.sh >> /root/backup.log &
nohup /root/monitor.sh >> /root/monitor.log &
```

**Use Cases:**
- Long-running tasks
- Background processes
- Remote scripts that survive disconnect
- Continuous operations

---

### 42. `ssh-keygen` - SSH Key Generator
Creates SSH authentication key pairs.

```bash
# Generate RSA key
ssh-keygen -t rsa -b 4096

# Generate ED25519 key (modern, more secure)
ssh-keygen -t ed25519 -C "user@email.com"

# Generate with specific filename
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_project

# List available keys
ls -la ~/.ssh/id_*

# Generate without passphrase
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

**Use Cases:**
- Set up SSH authentication
- Passwordless server access
- Git authentication
- Secure automation

---

### 43. `ssh-add` - SSH Agent Key Management
Adds private keys to SSH authentication agent.

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# Add multiple keys
ssh-add ~/.ssh/id_ed25519_server1
ssh-add ~/.ssh/id_ed25519_server2

# List loaded keys
ssh-add -l

# Remove all keys
ssh-add -D
```

**Use Cases:**
- Manage multiple SSH keys
- Avoid repeated passphrase entry
- Simplify SSH authentication
- Use different keys for different servers

---

### 44. `scp` - Secure Copy over SSH
Copies files between hosts securely.

```bash
# Copy file to remote server
scp /local/file.txt user@server:/remote/path/

# Copy from remote to local
scp user@server:/remote/file.txt /local/path/

# Copy directory recursively
scp -r /local/folder user@server:/remote/path/

# Copy with specific SSH key
scp -i ~/.ssh/key.pem file.txt user@server:/path/

# Copy using IP address
scp -r /home/user/backup.tar.gz root@172.20.1.26:/data/backup/
```

**Use Cases:**
- Transfer files between servers
- Backup to remote location
- Deploy applications
- Migrate data

---

### 45. `yum` - Package Manager (RHEL/CentOS)
Manages packages on Red Hat-based systems.

```bash
# Update package list and upgrade
yum update -y

# Install package
yum install nginx -y

# Install multiple packages
yum install nginx mysql-server redis -y

# Security updates only
yum --security check-update -y

# Update excluding kernel
yum -x 'kernel*' --security update --skip-broken --nobest

# Install plugin for security updates
yum install yum-plugin-security

# Get update information
yum updateinfo list security installed

# Install utilities
yum install bind-utils -y
yum install telnet -y

# Remove package
yum remove package-name -y
```

**Use Cases:**
- Install software on CentOS/RHEL
- Apply security patches
- Manage system packages
- Keep system updated

---

### 46. `mysqldump` - MySQL Database Backup
Exports MySQL/MariaDB databases.

```bash
# Backup single database
mysqldump -u root -p database_name > backup.sql

# Backup with timestamp
mysqldump -u root -p database_name > backup_$(date +%Y%m%d).sql

# Backup all databases
mysqldump -u root -p --all-databases > all_databases.sql

# Backup specific tables
mysqldump -u root -p database_name table1 table2 > tables_backup.sql
```

**Use Cases:**
- Database backups
- Database migration
- Version control for database schema
- Disaster recovery

---

### 47. `mongodump` - MongoDB Backup
Exports MongoDB databases.

```bash
# Backup specific database
mongodump --db database_name --out /backup/path

# Backup specific collection
mongodump --host IP --port 27017 --db login --collection User --out /backup/

# Backup from remote server
mongodump --host 10.20.30.40 --port 27017 --db test --out /backup/test/

# Full backup
mongodump --out /backup/full/
```

**Use Cases:**
- MongoDB backups
- Database migration
- Disaster recovery
- Development snapshots

---

### 48. `mongosh` - MongoDB Shell
Interactive MongoDB shell for database operations.

```bash
# Connect to MongoDB
mongosh

# Execute command quietly
/usr/bin/mongosh --quiet --eval 'rs.status()'

# Check replica set status
/usr/bin/mongosh --quiet --eval 'rs.status().members.forEach(m => print(m.name + " - " + m.stateStr))'

# Get current node state
/usr/bin/mongosh --quiet --eval 'rs.status().members.find(m => m.self).stateStr'

# Check compatibility version
db.adminCommand({ getParameter: 1, featureCompatibilityVersion: 1 })
```

**Use Cases:**
- Database administration
- Query databases
- Monitor replica sets
- Troubleshoot MongoDB issues

---

### 49. `docker` - Container Management
Manages Docker containers and images.

```bash
# Remove dangling images
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)

# List containers
docker ps

# List all containers (including stopped)
docker ps -a

# List images
docker images

# Remove container
docker rm container_id

# Remove image
docker rmi image_id

# Run container
docker run -d -p 80:80 nginx

# Stop container
docker stop container_id

# View logs
docker logs container_id
```

**Use Cases:**
- Container management
- Clean up unused images
- Deploy applications
- Development environments

---

### 50. `growpart` - Grow Partition
Expands partition size on cloud instances.

```bash
# Grow partition 5 on nvme0n1
sudo growpart /dev/nvme0n1 5

# After growing partition, extend filesystem
sudo xfs_growfs /
# OR for ext4
sudo resize2fs /dev/nvme0n1p5
```

**Use Cases:**
- Expand AWS EBS volumes
- Resize cloud instance disks
- Increase partition size
- Filesystem expansion

---

### 51. `shopt` - Shell Options
Sets shell behavior options.

```bash
# Enable extended globbing
shopt -s extglob

# Move all except specified directory
mv /path/!(exclude_this) /destination/

# Disable option
shopt -u extglob

# List all options
shopt
```

**Use Cases:**
- Enhanced pattern matching
- Complex file operations
- Shell scripting
- Advanced file management

---

### 52. `setenforce` - SELinux Mode Control
Changes SELinux enforcement mode.

```bash
# Disable SELinux temporarily
sudo setenforce 0

# Enable SELinux
sudo setenforce 1

# Make permanent (edit config)
sudo vi /etc/selinux/config
# Set: SELINUX=disabled or SELINUX=enforcing
```

**Use Cases:**
- Troubleshoot SELinux issues
- Temporarily disable SELinux
- Test without SELinux restrictions
- Security configuration

---

### 53. `reboot` - Restart System
Reboots the server.

```bash
# Immediate reboot
sudo reboot

# Reboot with message
sudo reboot "System maintenance"

# Scheduled reboot
sudo shutdown -r +10 "Rebooting in 10 minutes"

# Reboot at specific time
sudo shutdown -r 02:00
```

**Use Cases:**
- Apply kernel updates
- System maintenance
- Recover from issues
- Complete configuration changes

---

## Expert Level Commands

### 54. AWS CLI - Amazon Web Services Command Line
Manages AWS resources from command line.

```bash
# Configure AWS credentials
aws configure
aws configure list --profile profilename

# S3 Copy from Glacier
aws s3 cp s3://bucket/path/ local_path/ --force-glacier-transfer --profile profile --recursive

# S3 Sync
aws s3 sync s3://bucket/source/ /local/destination/ --profile profile

# S3 Copy with include/exclude
aws s3 cp s3://source/ s3://dest/ --exclude "*" --include "folder1/*" --recursive

# S3 Copy between buckets
aws s3 cp s3://source-bucket/ s3://dest-bucket/ --recursive --exclude "skip/*"

# S3 Remove with filters
aws s3 rm s3://bucket/ --recursive --exclude "keep/*"

# List S3 bucket
aws s3 ls s3://bucket-name/

# Copy to S3
aws s3 cp /local/file.txt s3://bucket/path/
```

**Use Cases:**
- Manage AWS resources
- Backup to S3
- Restore from Glacier
- Automate cloud operations

---

### 55. PowerShell Integration
Execute PowerShell commands from Linux or use in Windows.

```bash
# Get day name
powershell -Command "Get-Date -Format 'dddd'"

# Zabbix custom parameter
UserParameter=custom.day.name,powershell -Command "Get-Date -Format 'dddd'"

# Set AWS credentials
Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs 'profile'
```

**Use Cases:**
- Windows server management
- Cross-platform automation
- Integration with Windows services
- Custom monitoring scripts

---

### 56. `source` / `.` - Execute Script in Current Shell
Runs script in current shell environment (loads variables).

```bash
# Reload bash configuration
source ~/.bashrc

# Alternative syntax
. ~/.bashrc

# Load environment variables
source /etc/environment

# Apply profile changes
source ~/.bash_profile
```

**Use Cases:**
- Apply configuration changes
- Load environment variables
- Update PATH without logout
- Activate virtual environments

---

### 57. `export` - Set Environment Variables
Makes variables available to child processes.

```bash
# Set PATH variable
export PATH="/usr/local/bin:$PATH"

# Set custom variable
export HOSTNAME="server-01"
export NODE_ENV=production

# Add to bashrc for persistence
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc

# Multiple exports
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
```

**Use Cases:**
- Configure application environment
- Add directories to PATH
- Set build variables
- Configure service settings

---

### 58. `vi` / `nano` - Text Editors
Command-line text editors.

```bash
# Edit with nano (easier for beginners)
nano filename.txt
sudo nano /etc/config.conf

# Edit with vi/vim (more powerful)
vi filename.txt
sudo vi /etc/systemd/system/myservice.service

# Edit bashrc
vi ~/.bashrc

# Edit SELinux config
sudo vi /etc/selinux/config
```

**Vi Basic Commands:**
- `i` = Insert mode
- `Esc` = Command mode
- `:w` = Save
- `:q` = Quit
- `:wq` = Save and quit
- `:q!` = Quit without saving

**Use Cases:**
- Edit configuration files
- Write scripts
- Modify system files
- Create service definitions

---

### 59. Systemd Service Files
Create custom systemd services.

```bash
# Create MongoDB service
sudo nano /etc/systemd/system/mongod.service
```

```ini
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network.target

[Service]
User=root
ExecStart=/usr/bin/mongod --config /etc/mongod.conf
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/mongodb/mongod.pid
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Create Zabbix Agent service
sudo vi /etc/systemd/system/zabbix-agent.service
```

```ini
[Unit]
Description=Zabbix Agent
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/zabbix_agentd -c /etc/zabbix_agentd.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
# Create Zabbix Proxy service
sudo nano /etc/systemd/system/zabbix-proxy.service
```

```ini
[Unit]
Description=Zabbix Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/zabbix_proxy -c /usr/etc/zabbix_proxy.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
# After creating service file:
sudo systemctl daemon-reload
sudo systemctl enable service-name
sudo systemctl start service-name
sudo systemctl status service-name
```

**Use Cases:**
- Run applications as services
- Auto-start on boot
- Manage dependencies
- Ensure service restarts on failure

---

### 60. `/etc/rc.local` - Startup Script
Legacy method to run commands at boot (before systemd).

```bash
# Edit rc.local
sudo nano /etc/rc.local

# Add commands
/usr/local/sbin/zabbix_agentd -c /usr/local/etc/zabbix_agentd.conf &

# Make executable
sudo chmod +x /etc/rc.local
```

**Use Cases:**
- Run commands at startup (legacy systems)
- Start services before systemd
- Compatibility with older systems
- Quick boot scripts

---

### 61. Regular Expressions (Regex) Patterns
Advanced pattern matching used with grep, sed, awk.

```bash
# Remove comments
^#.*

# Remove empty lines
^\s*$

# Remove comments and empty lines
^#.*$\r?\n
^\s*$\r?\n

# Match numbers 1-161
\b(1[0-5][0-9]|16[0-1]|[1-9][0-9]?|1)\b

# Search with multiple patterns
grep -RE "net.ipv4.ip_forward|net.ipv6.conf.all.forwarding" /etc/
```

**Common Patterns:**
- `^` = Start of line
- `$` = End of line
- `.` = Any character
- `*` = Zero or more
- `+` = One or more
- `\s` = Whitespace
- `\b` = Word boundary
- `|` = OR operator

**Use Cases:**
- Advanced text searching
- Configuration file cleanup
- Log parsing
- Data validation

---

### 62. `htpasswd` - Apache Password File Management
Creates/manages HTTP authentication files.

```bash
# Create password with bcrypt (most secure)
htpasswd -bnBC 10 "" "password" | tr -d ':\n'

# Create/update password file
htpasswd -c /etc/apache2/.htpasswd username

# Add user to existing file
htpasswd /etc/apache2/.htpasswd newuser
```

**Use Cases:**
- Secure web directories
- Basic HTTP authentication
- Protect admin interfaces
- Simple access control

---

### 63. `openssl` - Cryptography and SSL/TLS Toolkit
Generates encrypted passwords and manages certificates.

```bash
# Generate SHA-512 password hash
openssl passwd -6 "your_password"

# Generate random password
openssl rand -base64 32

# Check SSL certificate
openssl s_client -connect example.com:443

# View certificate details
openssl x509 -in cert.pem -text -noout
```

**Use Cases:**
- Create secure password hashes
- Generate SSL certificates
- Test SSL/TLS connections
- Encrypt/decrypt data

---

### 64. MySQL Admin Commands
Advanced MySQL database operations.

```bash
# Update password with MD5 (less secure, use for legacy)
UPDATE users
SET passwd = MD5('password')
WHERE alias = 'username';

# Show column information
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'database_name' AND TABLE_NAME = 'table_name';
```

**Use Cases:**
- User management
- Database administration
- Schema inspection
- Password resets

---

### 65. Process and Cache Management Scripts
Advanced system optimization.

```bash
# Comprehensive cache clearing script
#!/bin/bash
# Clear page cache only
sync && echo 1 > /proc/sys/vm/drop_caches

# Clear dentries and inodes
sync && echo 2 > /proc/sys/vm/drop_caches

# Clear all caches
sync && echo 3 > /proc/sys/vm/drop_caches

# Monitor memory
free -h

# Check swap usage
grep Swap /proc/meminfo
```

**Use Cases:**
- Free up memory
- Performance testing
- Benchmark without cache
- Troubleshoot memory issues

---

### 66. Zabbix Agent/Proxy Commands
Monitoring system management.

```bash
# Start Zabbix Agent
/usr/sbin/zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf
/usr/local/sbin/zabbix_agentd -c /usr/local/etc/zabbix_agentd.conf

# Start Zabbix Proxy
/usr/sbin/zabbix_proxy -c /usr/etc/zabbix_proxy.conf

# Start Zabbix Server
/usr/sbin/zabbix_server -c /etc/zabbix/zabbix_server.conf

# Reload cache configuration
/usr/sbin/zabbix_proxy -R config_cache_reload
zabbix_proxy -R config_cache_reload
/usr/local/sbin/zabbix_agentd -R config_cache_reload

# View config (without comments and empty lines)
grep -v -e '^#' -e '^$' /usr/local/etc/zabbix_agentd.conf
grep -v -e '^#' -e '^$' /etc/zabbix/zabbix_server.conf

# Custom UserParameter example
UserParameter=custom.day.name,powershell -Command "Get-Date -Format 'dddd'"
```

**Use Cases:**
- Server monitoring
- Performance metrics collection
- Alert management
- Infrastructure monitoring

---

## Quick Command Reference Table

| Category | Commands |
|----------|----------|
| **Navigation** | pwd, cd, ls |
| **File Operations** | cp, mv, rm, touch, cat, truncate |
| **Search** | grep, find |
| **Text Processing** | awk, sed, tr, sort |
| **Permissions** | chmod, chown, usermod, setfacl |
| **Process Management** | ps, systemctl, service |
| **Network** | netstat, ss, nc, firewall-cmd, iptables |
| **Disk Management** | df, du, lsblk, growpart |
| **Archives** | tar |
| **Package Management** | yum |
| **Database** | mysqldump, mongodump, mongosh |
| **SSH** | ssh-keygen, ssh-add, scp |
| **Monitoring** | tail, history |
| **System** | reboot, sync, sysctl, setenforce |
| **Cloud** | aws (AWS CLI) |
| **Containers** | docker |
| **Scheduling** | crontab, nohup |

---

## Tips for Learning

### 1. Start with Basics
Master pwd, ls, cd, cat before moving to advanced commands.

### 2. Use `man` Pages
```bash
man command_name
man grep
man awk
```

### 3. Use `--help`
```bash
command_name --help
grep --help
tar --help
```

### 4. Practice in Safe Environment
- Use virtual machines or containers
- Test on non-production systems
- Make backups before modifications

### 5. Learn Pipes and Redirection
Combine commands for powerful operations:
```bash
ps aux | grep nginx | awk '{print $2}' | xargs kill
find /var/log -name "*.log" | xargs grep "error" | sort | uniq -c
```

### 6. Create Aliases for Common Commands
```bash
alias ll='ls -lah'
alias ..='cd ..'
alias logs='tail -f /var/log/syslog'
```

### 7. Use Command History
- `Ctrl + R` = Search history
- `!!` = Repeat last command
- `!grep` = Repeat last grep command

---

## Best Practices

### Security
- Use `sudo` for privileged operations
- Never run scripts from unknown sources as root
- Use SSH keys instead of passwords
- Set proper file permissions (especially for keys: 600)

### Efficiency
- Use tab completion
- Learn keyboard shortcuts
- Chain commands with `&&` (and) or `||` (or)
- Use pipes `|` to combine commands

### Safety
- Always backup before making changes
- Use `-i` flag for interactive prompts (rm -i, cp -i)
- Test commands on sample data first
- Keep backups of important config files

### Documentation
- Comment your scripts
- Keep notes of complex commands
- Document your processes
- Use meaningful filenames

---

## Next Steps

After mastering these commands, explore:

1. **Shell Scripting** - Automate tasks with bash scripts
2. **Version Control** - Learn Git commands
3. **Configuration Management** - Ansible, Puppet, Chef
4. **Container Orchestration** - Kubernetes commands
5. **Cloud CLI Tools** - Azure CLI, GCloud CLI
6. **Advanced Text Processing** - Perl, Python for text manipulation
7. **System Performance Tools** - strace, ltrace, perf, iotop
8. **Network Analysis** - tcpdump, wireshark, nmap

---

## 🧑‍💻 Author

**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: [linkedin.com/in/sarowar](https://www.linkedin.com/in/sarowar/)  
🐙 GitHub: [@md-sarowar-alam](https://github.com/md-sarowar-alam)

---

### License

This guide is provided as educational material for DevOps engineers.

---

**© 2026 Md. Sarowar Alam. All rights reserved.**
