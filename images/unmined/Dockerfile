FROM mcr.microsoft.com/dotnet/runtime:8.0-jammy

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Unmined version (override with --build-arg)
ARG UNMINED_VERSION=0.19.60
ARG UNMINED_ARCH=linux-x64

# Download and extract unmined-cli
RUN mkdir -p /opt/unmined && \
    curl -fL "https://unmined.net/download/unmined-cli_${UNMINED_ARCH}_${UNMINED_VERSION}.zip" \
      -o /tmp/unmined.zip && \
    unzip -q /tmp/unmined.zip -d /opt/unmined && \
    chmod +x /opt/unmined/unmined-cli && \
    rm /tmp/unmined.zip

ENV PATH="/opt/unmined:${PATH}"

# Non-root user (UID 1000 matches common fsGroup default)
RUN useradd -m -u 1000 unmined
USER 1000

WORKDIR /work

ENTRYPOINT ["unmined-cli"]
