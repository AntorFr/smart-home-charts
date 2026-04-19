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
# Downloads as gzipped tar containing unmined-cli_${VERSION}_linux-x64/ subdirectory
RUN mkdir -p /opt/unmined && \
    curl -fL "https://unmined.net/download/unmined-cli-linux-x64-${UNMINED_VERSION}/" \
      -o /tmp/unmined.tar.gz && \
    tar -xzf /tmp/unmined.tar.gz -C /tmp && \
    mv /tmp/unmined-cli_*_linux-x64/* /opt/unmined/ && \
    chmod +x /opt/unmined/unmined-cli && \
    rm -rf /tmp/unmined.tar.gz /tmp/unmined-cli_*

ENV PATH="/opt/unmined:${PATH}"

# Non-root user (UID 1000 matches common fsGroup default)
RUN useradd -m -u 1000 unmined
USER 1000

WORKDIR /work

ENTRYPOINT ["unmined-cli"]
