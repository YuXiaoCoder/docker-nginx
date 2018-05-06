#!/bin/bash

sed -i '/NGINX_ROOT/d' /etc/profile
sed -i '/NGINX_PORT/d' /etc/profile
sed -i '/NGINX_CONFD/d' /etc/profile

echo 'export NGINX_ROOT="/data/www/"' >> /etc/profile
echo 'export NGINX_PORT=80' >> /etc/profile
echo 'export NGINX_CONFD="/etc/nginx/conf.d/"' >> /etc/profile
source /etc/profile

SERVER_CONTAINER=$(docker ps -a | grep 'nginx-server' | awk '{print $1}')

if [[ -n "${SERVER_CONTAINER}" ]]; then
    docker stop nginx-server
    docker rm nginx-server
fi

docker run -d \
--name "nginx-server" \
-p ${NGINX_PORT}:80 \
-v ${NGINX_ROOT}:/data/www:ro \
-v ${NGINX_CONFD}:/etc/nginx/conf.d/:ro \
-v /var/log/nginx/:/var/log/nginx/ \
--restart=always \
docker-nginx

