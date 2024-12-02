FROM docker.io/library/ubuntu:22.04
# FROM https://hub.docker.com/_/ubuntu

LABEL com.github.containers.toolbox="true" \
    name="ubuntu-22-toolbox" \
    usage="This image is meant to be used with the toolbox or distrobox command" \
    summary="A cloud-native terminal experience powered by Ubuntu" \
    maintainer="drew@moseleynet.net"

COPY extra-packages /toolbox-packages
COPY xdg-open /usr/local/bin/
RUN chmod +x /usr/local/bin/xdg-open

RUN rm /etc/apt/apt.conf.d/docker-gzip-indexes /etc/apt/apt.conf.d/docker-no-languages && \
    sed -Ei 's/^(hosts:.*)(\<files\>)\s*(.*)/\1\2 myhostname \3/' /etc/nsswitch.conf && \
    sed -Ei '/apt-get (update|upgrade)/s/^/#/' /usr/local/sbin/unminimize
RUN apt-get update && \
    yes | /usr/local/sbin/unminimize && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    ubuntu-minimal ubuntu-standard \
    libnss-myhostname \
    flatpak-xdg-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    $(cat toolbox-packages | xargs)
RUN curl https://infinitekind.com/stabledl/current/moneydance_linux_amd64.deb -sLo /tmp/md.deb && \
    dpkg --install /tmp/md.deb && \
    rm -f /tmp/md.deb && \
RUN echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg && \
    install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null && \
    rm -f packages.microsoft.gpg && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install apt-transport-https && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install code
RUN wget -q https://packages.microsoft.com/config/ubuntu/$(grep VERSION_ID= /etc/os-release  | cut -d\" -f 2)/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm -f packages-microsoft-prod.deb && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install powershell
RUN rm /toolbox-packages && \
    mkdir /usr/share/empty && \
    userdel --remove ubuntu || true && \
    curl -sLo /usr/bin/host-spawn https://github.com/1player/host-spawn/releases/download/1.5.0/host-spawn-x86_64 && \
    chmod +x /usr/bin/host-spawn && \
    rm /etc/apt/apt.conf.d/20apt-esm-hook.conf && \
    ln -s /usr/libexec/flatpak-xdg-utils/flatpak-spawn /usr/bin/ && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/docker && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/flatpak && \ 
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/podman && \
    ln -fs /usr/bin/distrobox-host-exec /usr/local/bin/rpm-ostree && \
    echo "ALL ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
