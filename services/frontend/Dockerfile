# Multi-stage build for React Frontend
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Build the React app
RUN npm run build

# Production stage with Nginx
FROM nginx:alpine AS production

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user
RUN adduser -S frontend -u 1001

# Copy built React app to Nginx
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create necessary directories and set permissions
RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run /run && \
    chown -R frontend:nginx /var/log/nginx && \
    chown -R frontend:nginx /usr/share/nginx/html && \
    chown -R frontend:nginx /etc/nginx && \
    chown -R frontend:nginx /var/cache/nginx && \
    chown -R frontend:nginx /var/run && \
    chown -R frontend:nginx /run

# Expose port
EXPOSE 3000

# Switch to non-root user
USER frontend

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
