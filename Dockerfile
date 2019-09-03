FROM mcr.microsoft.com/powershell

RUN apt-get update && \
    apt-get install -y curl 

# install kubectl
RUN cd ~ && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# install Azure Powershell cmdlets
RUN pwsh -Command "& {Install-Module -Name Az -AllowClobber -Force}"
RUN pwsh -Command "& {Register-PackageSource -Name MyNuGet -Location https://www.nuget.org/api/v2 -ProviderName NuGet} "

COPY ./scripts /opt/scripts

ENTRYPOINT [ "/usr/bin/pwsh" ]
CMD ["./opt/scripts/main.ps1"]
