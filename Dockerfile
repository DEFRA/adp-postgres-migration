ARG  PS_IMAGE_VERSION=lts-alpine-3.17
FROM mcr.microsoft.com/powershell:${PS_IMAGE_VERSION}

USER root

ARG PS_USR_MODULES_PATH=/usr/local/share/powershell/Modules
COPY PreMigration ${PS_USR_MODULES_PATH}/PreMigration
COPY Migration ${PS_USR_MODULES_PATH}/Migration
COPY PostMigration ${PS_USR_MODULES_PATH}/PostMigration

COPY main.ps1 /main.ps1

SHELL ["pwsh", "-Command"]

ENTRYPOINT ["pwsh", "-File", "/main.ps1"]
CMD ["-h"]

