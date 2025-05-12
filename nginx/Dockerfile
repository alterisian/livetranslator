##############################
# Build the NGINX-build image.
FROM debian:bookworm-slim

# Default Nginx configuration values.
ENV RTMP_PORT=1935
ENV STREAM_KEY_NAME="${STREAM_KEY_NAME:-live}"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl \
        ffmpeg \
        gettext-base \
        nginx \
        libnginx-mod-rtmp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add NGINX path, config and static files.
COPY nginx.conf /etc/nginx/nginx.conf.template
RUN mkdir -p /opt/data

EXPOSE 1935

CMD envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && \
  nginx -g "daemon off;"
