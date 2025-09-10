# Base image with OpenJDK 17
FROM openjdk:17-slim

# Install curl, git, gnupg (required for SBT repo)
RUN apt-get update && \
    apt-get install -y curl git gnupg apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

# Add official SBT repository and import key
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x99E82A75642AC823" | apt-key add -

# Install SBT
RUN apt-get update && \
    apt-get install -y sbt && \
    rm -rf /var/lib/apt/lists/*

# Set working directory to project
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
