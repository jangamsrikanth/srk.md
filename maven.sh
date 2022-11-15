#!/bin/bash

echo "install JAVA"

sudo apt-get update
sudo apt install openjdk-11-jdk
java -version

echo "install maven"

Sudo apt-get install maven
mvn -version
