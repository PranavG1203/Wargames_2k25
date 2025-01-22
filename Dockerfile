# Stage 1: Build stage
FROM docker:20.10 as build

# Add any customizations, tools, or binaries here if needed
RUN apk add --no-cache bash curl git

# Stage 2: Runtime stage
FROM alpine:3.18

# Copy only the necessary files from the build stage
COPY --from=build /usr/local/bin/docker /usr/local/bin/docker

# Install runtime dependencies
RUN apk add --no-cache bash curl

# Create the working directory
WORKDIR /home/wlug

# Copy the levelup script into the container
COPY levelup.sh /usr/local/bin/levelup

# Ensure the script is executable
RUN chmod +x /usr/local/bin/levelup

# Default command
CMD ["sh"]
