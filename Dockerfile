# Builder Stage
FROM eclipse-temurin:17-jre-jammy

# Create liquibase user
RUN groupadd --gid 1001 liquibase && \
    useradd --uid 1001 --gid liquibase liquibase && \
    mkdir /liquibase && chown liquibase /liquibase

# Set Work Directory
WORKDIR /liquibase

# Download and install Liquibase
ARG LIQUIBASE_VERSION=4.28.0
ARG LB_SHA256=97dd07eaca0406a09e1ae19b407eea42a7e944c7f4571922bffce71b43b75ce8

RUN wget -q -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" && \
    echo "$LB_SHA256 *liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    rm liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    ln -s /liquibase/liquibase /usr/local/bin/liquibase && \
    ln -s /liquibase/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh && \
    liquibase --version

ARG LPM_VERSION=0.2.5
ARG LPM_SHA256=2ff5af7e850be8d768fb9e7ef2650e1584aec5bb2a7e92d34a7c71a25e7ff319
ARG LPM_SHA256_ARM=53197f652100a7cbc42851b300482c86846908d842400eabcf03eea3554b48f8

# Download and Install lpm
RUN apt-get update && apt-get install -yqq unzip --no-install-recommends && \
    mkdir /liquibase/bin && \
    arch="$(dpkg --print-architecture)" && \
    case "$arch" in \
      amd64)  DOWNLOAD_ARCH=""  ;; \
      arm64)  DOWNLOAD_ARCH="-arm64" && LPM_SHA256=${LPM_SHA256_ARM} ;; \
      *) echo >&2 "error: unsupported architecture '$arch'" && exit 1 ;; \
    esac && wget -q -O lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip "https://github.com/liquibase/liquibase-package-manager/releases/download/v${LPM_VERSION}/lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" && \
    echo "$LPM_SHA256 *lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" | sha256sum -c - && \
    unzip lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip -d bin/ && \
    rm lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip && \
    ln -s /liquibase/bin/lpm /usr/local/bin/lpm && \
    lpm --version && \
    apt-get purge -y --auto-remove unzip && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set LIQUIBASE_HOME environment variable
ENV LIQUIBASE_HOME=/liquibase

COPY liquibase.docker.properties ./

# Set user and group
USER liquibase:liquibase

USER root

# Install PowerShell in a single RUN command to reduce image size
RUN apt-get update && apt-get install -y wget apt-transport-https software-properties-common \
    # Download and install Microsoft repository GPG keys
    && wget -q "https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    # Clean up
    && apt-get purge -y --auto-remove wget apt-transport-https software-properties-common \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /packages-microsoft-prod.deb

COPY Modules /Modules
COPY main.ps1 /main.ps1
ENV PSModulePath="/Modules"

SHELL ["pwsh", "-Command"]

ENTRYPOINT ["pwsh", "-File", "/main.ps1"]
CMD ["-h"]