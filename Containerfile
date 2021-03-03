FROM registry.redhat.io/openshift4/ose-cli:latest

WORKDIR /opt/openshift-checks

RUN dnf clean all && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf install -y jq curl util-linux && \
    dnf clean all

RUN curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz | tar -C /usr/local/bin -xzf - oc kubectl 

RUN groupadd -g 9999 appuser && \
    useradd -r -u 9999 -g appuser appuser

COPY . /opt/openshift-checks

RUN chown -R appuser.appuser /opt/openshift-checks

USER appuser

ENTRYPOINT [ "/opt/openshift-checks/openshift-checks.sh" ]
