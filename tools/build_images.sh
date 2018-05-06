#!/bin/bash

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})

DOCKER_STATUS=$(systemctl is-active docker.service)

if [[ ${DOCKER_STATUS} != 'active' ]]; then
    echo -e "\033[1;31mError: Docker is not running.\033[0m"
    exit 1
fi

IMAGE_FLAG=$(docker images | awk '{print $1}' | grep '^docker-nginx')

if [[ ${IMAGE_FLAG} == 'docker-nginx' ]]; then
    docker ps -a | grep 'docker-nginx' | awk '{print $1}' | xargs -i -n 1 docker stop {}
    docker ps -a | grep 'docker-nginx' | awk '{print $1}' | xargs -i -n 1 docker rm {} 
    docker rmi docker-nginx
fi

# 构建镜像
docker build --no-cache --tag docker-nginx ${CWD}/../

