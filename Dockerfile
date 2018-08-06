# mssql-server-rhel
# Maintainers: Travis Wright (twright-msft on GitHub)
# GitRepo: https://github.com/twright-msft/mssql-server-rhel

# Base OS layer: latest CentOS 7
FROM centos:7

### Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="microsoft/mssql-server-linux" \
      vendor="Microsoft" \
      version="14.0" \
      release="1" \
      summary="MS SQL Server" \
      description="MS SQL Server is ....." \
### Required labels above - recommended below
      url="https://www.microsoft.com/en-us/sql-server/" \
      run='docker run --name ${NAME} \
        -e ACCEPT_EULA=Y -e SA_PASSWORD=yourStrong@Password \
        -p 1433:1433 \
        -d  ${IMAGE}' \
      io.k8s.description="MS SQL Server is ....." \
      io.k8s.display-name="MS SQL Server"

# Install latest mssql-server package
RUN curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2017.repo && \
    curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo && \
    ACCEPT_EULA=Y yum install -y mssql-server mssql-tools mssql-server-is unixODBC-devel && \
    yum clean all

COPY uid_entrypoint /opt/mssql-tools/bin/
ENV PATH=${PATH}:/opt/mssql/bin:/opt/mssql-tools/bin
RUN mkdir -p /var/opt/mssql/data && \
    mkdir -p /var/opt/ssis/packages/ && \
    chmod -R g=u /var/opt/mssql /var/opt/ssis/packages/ /etc/passwd

## Setup ssis
## It is envisaged to copy the SSIS packages in /var/opt/ssis/packages 
## and mount accordingly
ENV ACCEPT_EULA=Y
RUN /opt/ssis/bin/ssis-conf -n set-edition ; /opt/ssis/bin/ssis-conf -n setup ; exit 0

### Containers should not run as root as a good practice
#USER 10001

# Default SQL Server TCP/Port
EXPOSE 1433

## include the whole /var/opt/mssql as it 
## has also some precious encrypt data & logs
VOLUME /var/opt/mssql

### user name recognition at runtime w/ an arbitrary uid - for OpenShift deployments
ENTRYPOINT [ "uid_entrypoint" ]
# Run SQL Server process
CMD sqlservr
