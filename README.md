## Docker-Nginx

### 起因

+ 为了方便云服务器部署并升级`Nginx`, 故封装了`Docker`镜像;
+ 本镜像仅开放了`80`端口及`443`端口(若需要);
+ 请自行理解`docker`的端口映射及目录映射;

### 构建镜像

+ 通过`URL`构建镜像, 已知在`CentOS`云主机上无法使用:

```bash
docker build --no-cache -t docker-nginx https://github.com/YuXiaoCoder/docker-nginx.git#stable
```

+ 通过本地构建镜像, 先`clone`仓库到本地, 再构建镜像:

```bash
git clone https://github.com/YuXiaoCoder/docker-nginx.git
cd docker-nginx/
./tools/build_images.sh
```

### 创建配置文件

+ 创建`vhost`配置文件(请勿修改监听端口), 可以参考`conf/nginx`目录中的配置文件:

```bash
mkdir -p /etc/nginx/conf.d/
vim /etc/nginx/conf.d/vhost.conf
```

```text
server {
    listen 80;
    server_name localhost;
    access_log /var/log/nginx/default.access.log main;

    location / {
        root /data/www/;
        index index.html index.htm;
    }
}
```

```bash
mkdir -p /data/www/
echo 'Hello, World' >> /data/www/index.html
```

+ 已经在镜像中优化了`nginx.conf`配置, 若仍需自定义, 请自行配置:

```bash
mkdir -p /etc/nginx/
touch /etc/nginx/nginx.conf
```

### 设置环境变量

+ 设置映射端口号, 配置文件目录:

```bash
sed -i '/NGINX_ROOT/d' /etc/profile
sed -i '/NGINX_PORT/d' /etc/profile
sed -i '/NGINX_CONFD/d' /etc/profile
echo 'export NGINX_ROOT="/data/www/"' >> /etc/profile
echo 'export NGINX_PORT=80' >> /etc/profile
echo 'export NGINX_CONFD="/etc/nginx/conf.d/"' >> /etc/profile
source /etc/profile
```

+ 已经在镜像中了优化`nginx.conf`配置, 若仍需自定义, 请自行配置:

```bash
sed -i '/NGINX_CONF/d' /etc/profile
echo 'export NGINX_CONF="/etc/nginx/nginx.conf"' >> /etc/profile
```

### 运行容器

+ 测试`nginx`服务正常:

```bash
docker run -d --rm --name 'nginx' -p 8080:80 docker-nginx
curl 127.0.0.1:8080
docker stop nginx
```

+ 运行`nginx-server`容器:

```bash
docker run -d \
--name "nginx-server" \
-p ${NGINX_PORT}:80 \
-v ${NGINX_ROOT}:/data/www:ro \
-v ${NGINX_CONFD}:/etc/nginx/conf.d/:ro \
--restart=always \
docker-nginx
```

+ 如需加载自行配置的`nginx.conf`, 请加如下参数:

```bash
-v ${NGINX_CONF}:/etc/nginx/nginx.conf:ro
```

+ 如需访问日志文件, 请加如下参数:

```bash
-v /var/log/nginx/:/var/log/nginx/
```

***

