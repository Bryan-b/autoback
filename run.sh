#!/bin/bash

# Function to check if an INI file exists
check_ini_file() {
  if [ ! -f "backup.ini" ]; then
    echo "Creating a new INI file."
    touch backup.ini
    echo "db_user=" >> backup.ini
    echo "db_password=" >> backup.ini
    echo "db_name=" >> backup.ini
    echo "hasJob=false" >> backup.ini
    echo "Backup INI file created. Please enter database credentials in the INI file."
  fi
}

# Function to read INI file properties
read_ini_property() {
  local property_name="$1"
  local property_value=$(grep "$property_name" backup.ini | cut -d'=' -f2)
  echo "$property_value"
}

# Function to write to the INI file
write_ini_property() {
  local property_name="$1"
  local property_value="$2"
  sed -i "s/$property_name=.*/$property_name=$property_value/" backup.ini
}

# Function to add a cron job
add_cron_job() {
  local job_command="$1"
  (crontab -l ; echo "$job_command") | crontab -
}

# Function to check if the cron job is running
check_cron_status() {
  if crontab -l | grep -q "$1"; then
    echo "Cron job is running."
    echo "Number of times it has run: $(grep -c "$1" /var/log/syslog)"
    echo "Last run: $(grep "$1" /var/log/syslog | tail -n 1 | cut -d' ' -f1-3)"
  else
    echo "Cron job is not running."
  fi
}

case "$1" in
  "Init")
    check_ini_file
    ;;

  "Start")
    if [ "$(read_ini_property 'hasJob')" == "false" ]; then
      add_cron_job("0 0,12 * * * /bin/bash /path/to/your/backup-script.sh Backup")
      write_ini_property "hasJob" "true"
      echo "Automated backup is scheduled to run twice a day (12 AM and 12 PM)."
    else
      echo "Automated backup is already running."
    fi
    ;;

  "Backup")
    # MySQL backup logic (similar to the previous examples)
    DB_USER=$(read_ini_property "db_user")
    DB_PASSWORD=$(read_ini_property "db_password")
    DB_NAME=$(read_ini_property "db_name")
    BACKUP_DIR="/path/to/backup/directory"
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql"
    mkdir -p $BACKUP_DIR
    mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_FILE
    ;;

  "Stop")
    crontab -l | grep -v "/bin/bash /path/to/your/backup-script.sh Backup" | crontab -
    write_ini_property "hasJob" "false"
    echo "Automated backup has been stopped."
    ;;

  "Status")
    check_cron_status "/bin/bash /path/to/your/backup-script.sh Backup"
    ;;

  *)
    echo "Usage: $0 [Init|Start|Backup|Stop|Status]"
    ;;
esac