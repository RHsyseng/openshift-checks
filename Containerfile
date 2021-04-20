FROM registry.access.redhat.com/ubi8/ubi:latest

ENV YQVERSION="v4.6.3" \
    YQARCH="linux_amd64"

WORKDIR /opt/openshift-checks

# Some required binaries
RUN dnf clean all && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf update -y && \
    dnf install -y jq curl util-linux bind-utils && \
    dnf clean all

# YQ doesn't provide a RPM
RUN curl -sL https://github.com/mikefarah/yq/releases/download/${YQVERSION}/yq_${YQARCH} -o /usr/local/bin/yq &&\
    chmod a+x /usr/local/bin/yq

# Download latest oc binary
RUN curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz | tar -C /usr/local/bin -xzf - oc kubectl

RUN groupadd -g 9999 appuser && \
    useradd -r -u 9999 -g appuser appuser

COPY . /opt/openshift-checks

RUN chown -R appuser.appuser /opt/openshift-checks

USER appuser

ENTRYPOINT [ "/opt/openshift-checks/openshift-checks.sh" ]
