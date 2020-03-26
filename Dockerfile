FROM alpine:latest

# Standard set up Nginx Alpine
# https://github.com/nginxinc/docker-nginx/blob/1.14.0/mainline/alpine/Dockerfile

ENV NGINX_VERSION "1.16.1"

RUN \
  sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
  apk update && apk upgrade && \
  CONFIG="\
  --user=nginx \
  --group=nginx \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --with-mail \
  --with-stream \
  --with-compat \
  --with-threads \
  --with-file-aio \
  --with-http_v2_module \
  --with-mail_ssl_module \
  --with-http_sub_module \
  --with-http_ssl_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_slice_module \
  --with-stream_ssl_module \
  --with-http_realip_module \
  --with-http_gunzip_module \
  --with-http_addition_module \
  --with-stream_realip_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-http_secure_link_module \
  --with-http_auth_request_module \
  --with-http_xslt_module=dynamic \
  --with-http_random_index_module \
  --with-http_geoip_module=dynamic \
  --with-stream_ssl_preread_module \
  --with-stream_geoip_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  " && \
  addgroup -S nginx && \
  adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx && \
  apk add --virtual .build-deps gcc libc-dev make openssl-dev pcre-dev zlib-dev linux-headers curl libxslt-dev gd-dev geoip-dev gettext && \
  curl -fsSLO --compressed https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  mkdir -p /usr/src/nginx/ && \
  tar -zxf nginx-${NGINX_VERSION}.tar.gz --strip-components=1 -C /usr/src/nginx/ && \
  rm -f nginx-${NGINX_VERSION}.tar.gz && \
  cd /usr/src/nginx/ && \
  ./configure ${CONFIG} --with-debug && \
  make -j $(getconf _NPROCESSORS_ONLN) && \
  mv objs/nginx objs/nginx-debug && \
  mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so && \
  mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so && \
  mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so && \
  mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so && \
  ./configure ${CONFIG} && \
  make -j $(getconf _NPROCESSORS_ONLN) && \
  make install && \
  rm -rf /etc/nginx/html/ && \
  mkdir /etc/nginx/conf.d/ && \
  mkdir -p /usr/share/nginx/html/ && \
  install -m644 html/index.html /usr/share/nginx/html/ && \
  install -m644 html/50x.html /usr/share/nginx/html/ && \
  install -m755 objs/nginx-debug /usr/sbin/nginx-debug && \
  install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so && \
  install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so && \
  install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so && \
  install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so && \
  ln -s ../../usr/lib/nginx/modules /etc/nginx/modules && \
  strip /usr/sbin/nginx* && \
  strip /usr/lib/nginx/modules/*.so && \
  rm -rf /usr/src/nginx/ && \
  mv -f /usr/bin/envsubst /tmp/ && \
  runDeps="$( \
      scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }')" && \
  apk add --virtual .nginx-rundeps ${runDeps} && \
  apk del .build-deps && \
  mv /tmp/envsubst /usr/local/bin/ && \
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log

# Custom Nginx config
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/nginx.vh.default.conf /etc/nginx/conf.d/default.conf

# Expose 80 and 443, in case of LTS / HTTPS
EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
