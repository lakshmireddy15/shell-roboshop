#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
SCRIPT_DIR=$PWD
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
dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "disabling MongoDB service"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "Enabling MongoDB service"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "Installing MongoDB service"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOG_FILE
VALIDATE $? "creating system user"

mkdir /app 
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOG_FILE
VALIDATE $? "Download app catalogue"
cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping catalogue files"
npm install &>>LOG_FILE
VALIDATE $? "Installing all dependies"

cp SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>LOG_FILE
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>>LOG_FILE
VALIDATE $? "reloading  catalogue service"

systemctl enable catalogue &>>LOG_FILE
VALIDATE $? "enabling catalogue service"
systemctl start catalogue &>>LOG_FILE
VALIDATE $? "starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo 

dnf install mongodb-mongosh -y &>>LOG_FILE
VALIDATE $? "installing mongodb client"

mongosh --host mongodb.lakshmireddy.site </app/db/master-data.js &>>LOG_FILE