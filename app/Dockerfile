# Multi-platform support for AWS EKS (amd64 and arm64)
FROM --platform=$TARGETPLATFORM nginx:alpine

# Build arguments for platform detection
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Build arguments for version and build time
ARG APP_VERSION=v1
ARG BUILD_TIME="unknown"
ARG VERSION_TYPE="stable"

# Copy index.html for processing
COPY index.html /tmp/index.html

# Replace placeholders with actual values
RUN sed -e "s|VERSION_NUMBER|${APP_VERSION}|g" \
        -e "s|BUILD_TIME|${BUILD_TIME}|g" \
        -e "s|VERSION_TYPE|${VERSION_TYPE}|g" \
        -e "s|VERSION_CLASS|version-${APP_VERSION}|g" \
        /tmp/index.html > /usr/share/nginx/html/index.html && \
    rm /tmp/index.html

# Add architecture info for debugging
RUN echo "Built for: ${TARGETPLATFORM}" > /usr/share/nginx/html/platform.txt

# Run as non-root user for security (required for EKS security best practices)
RUN addgroup -g 101 -S nginx && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx 2>/dev/null || true && \
    chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    chmod -R 755 /usr/share/nginx/html && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
