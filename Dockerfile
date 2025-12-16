# Use nginx alpine for a lightweight image
FROM nginx:alpine

# Set build argument for version
ARG VERSION=v1.0.0

# Remove default nginx index page
RUN rm -rf /usr/share/nginx/html/*

# Copy our custom index.html
COPY index.html /tmp/index.html

# Replace VERSION placeholder with actual version and move to nginx html directory
RUN sed "s/{{VERSION}}/${VERSION}/g" /tmp/index.html > /usr/share/nginx/html/index.html && \
    rm /tmp/index.html

# Create a custom nginx configuration for better logging
RUN echo 'server { \
    listen 80; \
    server_name _; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
    } \
    location /health { \
        access_log off; \
        return 200 "healthy\n"; \
        add_header Content-Type text/plain; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
