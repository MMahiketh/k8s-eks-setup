#!/bin/bash

#/var/log/setup-workstation/<file-name>-<timestamp>.log
LOG_FOLDER="/var/log/setup-workstation/"
SCRIPT_NAME=$(echo $0 | awk -F "/" '{print $NF}' | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d::%H:%M:%S)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
USERID=$(id -u)

AWS_CONFIG_FOLDER="/home/ec2-user/.aws/"

mkdir -p $LOG_FOLDER

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

PLATFORM=Linux_amd64

VALIDATE(){

	if [ $1 -ne 0 ]
	then
		echo -e "$2 ... $R FAILED $N" | tee -a $LOG_FILE
		
		if [ $# -eq 3 ]
		then
			echo -e "$3" | tee -a $LOG_FILE
			exit 1
		fi
	else
		echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
	fi

}

#Check for root user
VALIDATE $USERID "Root user access" "Please execute the script as root user. Exiting..."

# aws configure
mkdir -p $AWS_CONFIG_FOLDER
VALIDATE $? "Creating .aws dir" "Failed to create dir. Exiting..."
echo -e '[default]\nregion = us-east-1' > "$AWS_CONFIG_FOLDER/config"

chown -R ec2-user:ec2-user /home/ec2-user


# install docker and git
yum update -y &>> $LOG_FILE
yum -y install docker git &>> $LOG_FILE
VALIDATE $? "Installing docker and git" "Failed to install. Exiting..."

# start docker
service docker start &>> $LOG_FILE
VALIDATE $? "Starting docker service"

# setup docker
usermod -a -G docker ec2-user
chmod 666 /var/run/docker.sock

docker --version &>> $LOG_FILE
VALIDATE $? "Test docker"

# download k8s
curl -OL https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.0/2024-12-20/bin/linux/amd64/kubectl &>> $LOG_FILE
VALIDATE $? "Downloading kubectl" "Failed to download. Exiting..."

# install k8s
chmod +x kubectl
mv kubectl /usr/local/bin
VALIDATE $? "Installing kubectl" "Failed to move kubectl. Exiting..."

kubectl version --client &>> $LOG_FILE
VALIDATE $? "Test kubectl"


# download eksctl
curl -OL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" &>> $LOG_FILE
VALIDATE $? "Download eksctl" "Failed to download. Exiting..."

# unarchive eksctl
tar -xzvf eksctl_$PLATFORM.tar.gz &>> $LOG_FILE
VALIDATE $? "Unarchive eksctl" "Failed to extract. Exiting..."

# install eksctl
chmod +x eksctl
mv eksctl /usr/local/bin
VALIDATE $? "Installing eksctl" "Failed to move eksctl. Exiting..."

eksctl version &>> $LOG_FILE
VALIDATE $? "Test eksctl"


# Create eks cluster
cd /home/ec2-user/
git clone https://github.com/MMahiketh/k8s-eks-setup.git

chown -R ec2-user:ec2-user /home/ec2-user

# sleep 60
# eksctl create cluster --config-file=k8s-eks-setup/eks.yaml --dry-run