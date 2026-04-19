FROM mcr.microsoft.com/dotnet/runtime:8.0-jammy

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Unmined version (override with --build-arg)
ARG UNMINED_VERSION=dev

# Download and extract unmined-cli
# Format: https://unmined.net/download/unmined-cli-linux-x64-${UNMINED_VERSION}/
# Downloads as gzipped tar
RUN mkdir -p /opt/unmined && \
    curl -fL "https://unmined.net/download/unmined-cli-linux-x64-${UNMINED_VERSION}/" \
      -o /tmp/unmined.tar.gz && \
    tar -xzf /tmp/unmined.tar.gz -C /opt/unmined && \
    chmod +x /opt/unmined/unmined-cli && \
    rm /tmp/unmined.tar.gz

ENV PATH="/opt/unmined:${PATH}"

# Non-root user (UID 1000 matches common fsGroup default)
RUN useradd -m -u 1000 unmined
USER 1000

WORKDIR /work

ENTRYPOINT ["unmined-cli"]
