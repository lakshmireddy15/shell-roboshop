#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Log file setup
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# Check for root access
if [ $USERID -ne 0 ]; then
  echo -e "${R}ERROR:: Please run this script with root access${N}" | tee -a $LOG_FILE
  exit 1
else
  echo "You are running with root access" | tee -a $LOG_FILE
fi

# Read RabbitMQ password
read -s -p "Please enter RabbitMQ password to setup: " RABBITMQ_PASSWD
echo

# Validation function
VALIDATE() {
  if [ $1 -eq 0 ]; then
    echo -e "$2 is ... ${G}SUCCESS${N}" | tee -a $LOG_FILE
  else
    echo -e "$2 is ... ${R}FAILURE${N}" | tee -a $LOG_FILE
    exit 1
  fi
}

# Add RabbitMQ repo
cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Adding RabbitMQ repo"

# Install RabbitMQ server
dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing RabbitMQ server"

# Enable and start RabbitMQ service
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enabling RabbitMQ server"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Starting RabbitMQ server"

# Add user and set permissions
rabbitmqctl add_user roboshop "$RABBITMQ_PASSWD" &>>$LOG_FILE
VALIDATE $? "Adding RabbitMQ user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "Setting RabbitMQ user permissions"

# Final output
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Script execution completed successfully, ${Y}time taken: $TOTAL_TIME seconds${N}" | tee -a $LOG_FILE
