ARG  PS_IMAGE_VERSION=lts-alpine-3.17
FROM mcr.microsoft.com/powershell:${PS_IMAGE_VERSION}

USER root

COPY Modules /Modules
COPY main.ps1 /main.ps1
ENV PSModulePath="/Modules"

SHELL ["pwsh", "-Command"]

ENTRYPOINT ["pwsh", "-File", "/main.ps1"]
CMD ["-h"]

