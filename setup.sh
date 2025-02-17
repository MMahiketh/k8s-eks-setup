#!/bin/bash

#/var/log/setup-workstation/<file-name>-<timestamp>.log
LOG_FOLDER="/var/log/setup-workstation/"
SCRIPT_NAME=$(echo $0 | awk -F "/" '{print $NF}' | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d::%H:%M:%S)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
USERID=$(id -u)

mkdir -p $LOG_FOLDER

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

PLATFORM=$(uname -s)_amd64 #Linux_amd64

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

cd /tmp

# download 
  # k8s
    curl -OL https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.0/2024-12-20/bin/linux/amd64/kubectl &>> $LOG_FILE
    VALIDATE $? "Downloading kubectl"

  # eksctl
    curl -OL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" &>> $LOG_FILE
    VALIDATE $? "Download eksctl"
    # unarchive
    tar -xzvf eksctl_$PLATFORM.tar.gz &>> $LOG_FILE
    VALIDATE $? "Unarchive eksctl"

  # kubectx
    curl -OL https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/kubectx
    VALIDATE $? "Download kubectx"

  # kubens
    curl -OL https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/kubens
    VALIDATE $? "Download kubens"

  # helm installation script
    curl -L -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 &>> $LOG_FILE
    VALIDATE $? "Downloading helm installation script"


# install
  yum update -y &>> $LOG_FILE
  VALIDATE $? "Updating yum" "Failed to update. Exiting..."
  # git
    yum -y install git &>> $LOG_FILE
    VALIDATE $? "Installing git"
 # docker
    yum -y install docker &>> $LOG_FILE
    VALIDATE $? "Installing docker"
  # k8s
    chmod +x kubectl
    mv kubectl /usr/local/bin
    VALIDATE $? "Installing kubectl"
  # eksctl
    chmod +x eksctl
    mv eksctl /usr/local/bin
    VALIDATE $? "Installing eksctl"
  # kubens
    chmod +x kubectx
    mv kubectx /usr/local/bin
    VALIDATE $? "Installing kubectx"
  # kubens
    chmod +x kubens
    mv kubens /usr/local/bin
    VALIDATE $? "Installing kubens"
  # helm
    chmod +x get_helm.sh
    ./get_helm.sh
    VALIDATE $? "Installing helm"

# test
  # docker
    docker --version &>> $LOG_FILE
    VALIDATE $? "Test docker"
  # kubectl
    kubectl version --client &>> $LOG_FILE
    VALIDATE $? "Test kubectl"
  # eksctl
    eksctl version &>> $LOG_FILE
    VALIDATE $? "Test eksctl" 
  # helm
    helm version --short &>> $LOG_FILE
    VALIDATE $? "Test helm"

# docker
  # start
    service docker start &>> $LOG_FILE
    VALIDATE $? "Starting docker service"
  # config
    usermod -a -G docker ec2-user
    chmod 666 /var/run/docker.sock