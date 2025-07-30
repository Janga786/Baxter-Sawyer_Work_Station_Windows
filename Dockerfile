# Use a standard Ubuntu image as the base
FROM ubuntu:22.04

# Set environment variables to prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    build-essential \
    python3-pip \
    ros-humble-desktop \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN useradd -ms /bin/bash baxter
USER baxter
WORKDIR /home/baxter/baxter_station

# Copy the source code
COPY . .

# Install Python dependencies
# Assuming a requirements.txt file exists in the root of the project
RUN pip3 install --user -r requirements.txt

# Make the entrypoint script executable
RUN chmod +x entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["./entrypoint.sh"]

