# Frontend Dockerfile — Nginx serving static HTML
FROM nginx:1.25-alpine

# Install curl so the healthcheck works on alpine
RUN apk add --no-cache curl

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy our frontend
COPY index.html /usr/share/nginx/html/index.html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80