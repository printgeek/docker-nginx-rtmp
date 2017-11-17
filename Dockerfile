FROM alpine:3.3
MAINTAINER Alfred Gutierrez <alf.g.jr@gmail.com>

ENV NGINX_VERSION 1.13.6
ENV NGINX_RTMP_VERSION 1.2.0
ENV FFMPEG_VERSION 3.4

RUN mkdir -p /opt/data && mkdir /www

RUN	apk update && apk add	\
  gcc binutils-libs binutils build-base libgcc make pkgconf pkgconfig \
  openssl openssl-dev ca-certificates pcre \
  musl-dev libc-dev pcre-dev zlib-dev

# Get nginx source.
RUN cd /tmp && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar zxf nginx-${NGINX_VERSION}.tar.gz \
  && rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz \
  && tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} \
  && ./configure \
  --prefix=/opt/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/opt/nginx/nginx.conf --error-log-path=/opt/nginx/logs/error.log --http-log-path=/opt/nginx/logs/access.log \
  --with-debug
RUN cd /tmp/nginx-${NGINX_VERSION} && make && make install

# ffmpeg dependencies.
RUN apk add --update nasm yasm-dev lame-dev libogg-dev x264-dev libvpx-dev libvorbis-dev x265-dev freetype-dev libass-dev libwebp-dev rtmpdump-dev libtheora-dev opus-dev
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
RUN apk add --update fdk-aac-dev

# Get ffmpeg source.
RUN cd /tmp/ && wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz \
  && tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# Compile ffmpeg.
RUN cd /tmp/ffmpeg-${FFMPEG_VERSION} && \
  ./configure \
  --enable-version3 \
  --enable-gpl \
  --enable-nonfree \
  --enable-small \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libfdk-aac \
  --enable-libass \
  --enable-libwebp \
  --enable-librtmp \
  --enable-postproc \
  --enable-avresample \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  && make && make install && make distclean



# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

EXPOSE 80 1935

VOLUME /www/static /opt/nginx/html

COPY nginx.conf /opt/nginx/nginx.conf
COPY nginx.conf /opt/nginx/nginx.conf.SD
COPY nginx.conf /opt/nginx/nginx.conf.HD
COPY static /www/static
COPY html /opt/nginx/html

RUN mkdir /opt/nginx/html/js
RUN mkdir /opt/nginx/html/css
RUN cd /opt/nginx/html/js && wget https://code.jquery.com/jquery-3.2.1.min.js \
  && wget https://code.jquery.com/jquery-1.11.2.min.js \
  && wget https://cdnjs.cloudflare.com/ajax/libs/videojs-contrib-hls/5.12.2/videojs-contrib-hls.min.js \
  && wget "http://vjs.zencdn.net/6.2.8/video.min.js"
RUN cd /opt/nginx/html/css && wget "http://vjs.zencdn.net/6.2.8/video-js.css"

CMD ["/opt/nginx/sbin/nginx"]
