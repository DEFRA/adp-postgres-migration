# Builder Stage
FROM eclipse-temurin:17-jre-jammy

# Create liquibase user
RUN groupadd --gid 1001 liquibase && \
    useradd --uid 1001 --gid liquibase liquibase && \
    mkdir /liquibase && chown liquibase /liquibase

# Download and install Liquibase
WORKDIR /liquibase

ARG LIQUIBASE_VERSION=4.28.0
ARG LB_SHA256=97dd07eaca0406a09e1ae19b407eea42a7e944c7f4571922bffce71b43b75ce8

RUN wget -q -O liquibase-${LIQUIBASE_VERSION}.tar.gz "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz" && \
    echo "$LB_SHA256 *liquibase-${LIQUIBASE_VERSION}.tar.gz" | sha256sum -c - && \
    tar -xzf liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    rm liquibase-${LIQUIBASE_VERSION}.tar.gz && \
    ln -s /liquibase/liquibase /usr/local/bin/liquibase && \
    liquibase --version

ARG LPM_VERSION=0.2.6
ARG LPM_SHA256=0e1df6b8daf9d53a2d1d90fa8e48abbcbb8e885d249de7a09879a3a0276bebdf
ARG LPM_SHA256_ARM=b1f6d5c8b21353b213ef828849c3d767d4214e13e8c0f4fbadd038c96ef93389

# Download and Install lpm
RUN apt-get update && \
    apt-get -yqq install unzip --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /liquibase/bin && \
    arch="$(dpkg --print-architecture)" && \
    case "$arch" in \
      amd64)  DOWNLOAD_ARCH=""  ;; \
      arm64)  DOWNLOAD_ARCH="-arm64" && LPM_SHA256=$LPM_SHA256_ARM ;; \
      *) echo >&2 "error: unsupported architecture '$arch'" && exit 1 ;; \
    esac && wget -q -O lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip "https://github.com/liquibase/liquibase-package-manager/releases/download/v${LPM_VERSION}/lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" && \
    echo "$LPM_SHA256 *lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip" | sha256sum -c - && \
    unzip lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip -d bin/ && \
    rm lpm-${LPM_VERSION}-linux${DOWNLOAD_ARCH}.zip && \
    apt-get purge -y --auto-remove unzip && \
    ln -s /liquibase/bin/lpm /usr/local/bin/lpm && \
    lpm --version

# Set LIQUIBASE_HOME environment variable
ENV LIQUIBASE_HOME=/liquibase

COPY liquibase.docker.properties ./

# Set user and group
USER liquibase:liquibase


USER root

RUN apt-get update && \
    apt-get install -y wget apt-transport-https software-properties-common && \
    wget -q "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell postgresql-client && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /packages-microsoft-prod.deb

RUN pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"
RUN pwsh -Command "Install-Module -Name Az.Accounts -Force -AllowClobber"
RUN pwsh -Command "Install-Module -Name Az.KeyVault -Force -AllowClobber"

WORKDIR /

COPY Modules ./Modules
COPY main.ps1 ./

ENV PSModulePath="/Modules"

SHELL ["pwsh", "-Command"]

ENTRYPOINT ["pwsh", "-File", "/main.ps1"]
CMD ["-h"]