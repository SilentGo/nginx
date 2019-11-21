FROM alpine

MAINTAINER liuz "llzmac@163.com"

ENV NGINX_VERSION 1.17.5
ENV LUAJIT_LIB=/usr/local/luajit/lib
ENV LUAJIT_INC=/usr/local/luajit/include/luajit-2.1
    
RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
    && CONFIG="\
        --prefix=/usr/local/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/local/nginx/modules \
        --conf-path=/usr/local/nginx/conf/nginx.conf \
        --pid-path=/usr/local/nginx/logs/nginx.pid \
        --lock-path=/usr/local/nginx/logs/nginx.lock \
        --http-client-body-temp-path=/usr/local/nginx/client_temp \
        --http-proxy-temp-path=/usr/local/nginx/proxy_temp \
        --http-fastcgi-temp-path=/usr/local/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/usr/local/nginx/uwsgi_temp \
        --http-scgi-temp-path=/usr/local/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-stream_realip_module \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-compat \
        --with-file-aio \
        --with-http_v2_module \
        --with-cc-opt='-I/usr/local/include' \
        --with-ld-opt='-L/usr/local/lib' \
        --with-ld-opt="-Wl,-rpath,/usr/local/luajit/lib" \
        --add-module=/tmp/ngx_http_geoip2_module \
        --add-module=/tmp/nginx-module-vts \
        --add-module=/tmp/nginx_upstream_check_module \
        --add-module=/tmp/ngx_devel_kit-0.3.1 \
        --add-module=/tmp/lua-nginx-module-0.10.15 \
        --add-module=/tmp/ngx_http_proxy_connect_module \
    " \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        git \
        make \
        automake \
        autoconf \
        libtool \
        linux-headers \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o /tmp/nginx.tar.gz \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o /tmp/nginx.tar.gz.asc \
    && curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v0.3.1.tar.gz  -o /tmp/v0.3.1.tar.gz \
    && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v0.10.15.tar.gz  -o /tmp/v0.10.15.tar.gz \
    && git clone --recursive https://github.com/maxmind/libmaxminddb.git /tmp/libmaxminddb \
    && git clone --recursive https://github.com/leev/ngx_http_geoip2_module.git /tmp/ngx_http_geoip2_module \
    && git clone https://github.com/vozlt/nginx-module-vts.git /tmp/nginx-module-vts \
    && git clone https://github.com/yaoweibin/nginx_upstream_check_module.git /tmp/nginx_upstream_check_module \
    && git clone https://github.com/openresty/luajit2.git /tmp/luajit2 \
    && git clone https://github.com/chobits/ngx_http_proxy_connect_module.git /tmp/ngx_http_proxy_connect_module \ 
    && export GNUPGHOME="$(mktemp -d)" \
    && found=''; \
    for server in \
        ha.pool.sks-keyservers.net \
        hkp://keyserver.ubuntu.com:80 \
        hkp://p80.pool.sks-keyservers.net:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $GPG_KEYS from $server"; \
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
    gpg --batch --verify /tmp/nginx.tar.gz.asc /tmp/nginx.tar.gz \
    && rm -rf "$GNUPGHOME" /tmp/nginx.tar.gz.asc \
    && export CFLAGS="-O2" \
        CPPFLAGS="-O2" \
        LDFLAGS="-O2" \
    && cd /tmp/libmaxminddb \
    && ./bootstrap \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && cd /tmp/luajit2 && make PREFIX=/usr/local/luajit && make install PREFIX=/usr/local/luajit \
    && cd /tmp && tar -xf v0.3.1.tar.gz \
    && cd /tmp && tar -xf v0.10.15.tar.gz \
    && cd /tmp && tar -xf nginx.tar.gz \
    && cd /tmp/nginx-$NGINX_VERSION \
    && patch -p1 < /tmp/nginx_upstream_check_module/check_1.16.1+.patch \
    && patch -p1 < /tmp/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_101504.patch \
    && ./configure $CONFIG \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && mkdir -p /usr/local/nginx/html/ \
    && install -m644 html/index.html /usr/local/nginx/html/ \
    && install -m644 html/50x.html /usr/local/nginx/html/ \
    && strip /usr/sbin/nginx* \
    && strip /usr/local/nginx/modules/*.so \
    && rm -rf /tmp/* \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/sbin/nginx /usr/local/nginx/modules/*.so /usr/local/luajit/lib/*.so.2 /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps \
    && apk --no-cache add tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del .build-deps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/

COPY ./conf/nginx.conf /usr/local/nginx/conf/nginx.conf
COPY ./conf/vhosts /usr/local/nginx/conf/vhosts

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
