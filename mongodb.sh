#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
SCRIPT_DIRECTORY=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# Check for root access
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# Validate function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

# Create MongoDB repo file
cat > /etc/yum.repos.d/mongodb.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/7.0/x86_64/
enabled=1
gpgcheck=0
EOF

VALIDATE $? "Creating MongoDB repo"

# Install MongoDB
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB server"

# Enable MongoDB
systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB service"

# Start MongoDB
systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting MongoDB service"

# Update bind IP for remote access
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Updating MongoDB bind IP"

# Restart MongoDB
systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB service"
