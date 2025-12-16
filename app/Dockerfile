FROM nginx:alpine

# Build arguments for version and build time
ARG APP_VERSION=v1
ARG BUILD_TIME="unknown"
ARG VERSION_TYPE="stable"
COPY index.html /tmp/index.html

RUN sed -e "s|VERSION_NUMBER|${APP_VERSION}|g" \
        -e "s|BUILD_TIME|${BUILD_TIME}|g" \
        -e "s|VERSION_TYPE|${VERSION_TYPE}|g" \
        -e "s|VERSION_CLASS|version-${APP_VERSION}|g" \
        /tmp/index.html > /usr/share/nginx/html/index.html && \
    rm /tmp/index.html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
