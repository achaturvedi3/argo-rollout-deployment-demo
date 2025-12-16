FROM nginx:alpine

# Build arguments for version and build time
ARG APP_VERSION=v1
ARG BUILD_TIME="unknown"
ARG VERSION_TYPE="stable"

# Copy custom nginx configuration if needed
# COPY nginx.conf /etc/nginx/nginx.conf

# Copy the HTML template
COPY index.html /tmp/index.html

# Replace placeholders with actual values and copy to nginx root
RUN sed -e "s|VERSION_NUMBER|${APP_VERSION}|g" \
        -e "s|BUILD_TIME|${BUILD_TIME}|g" \
        -e "s|VERSION_TYPE|${VERSION_TYPE}|g" \
        -e "s|VERSION_CLASS|version-${APP_VERSION}|g" \
        /tmp/index.html > /usr/share/nginx/html/index.html && \
    rm /tmp/index.html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
