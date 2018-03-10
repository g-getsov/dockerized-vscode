FROM debian:buster-slim

# Add buster non free and contrib source list
RUN echo "deb http://ftp.ua.debian.org/debian buster contrib non-free" | tee -a /etc/apt/sources.list.d/docker.list && \
echo "deb-src http://ftp.ua.debian.org/debian buster contrib non-free" | tee -a /etc/apt/sources.list.d/docker.list

# Disable terminal prompt interaction during setup
ENV DEBIAN_FRONTEND=noninteractive 

# Install dependencies
RUN apt-get update && \
apt-get -y install \
curl \
gpg \
pulseaudio \
git \
nvidia-driver \
freeglut3-dev \
libxcursor-dev \
libxi-dev \
libxrandr-dev \
libxinerama-dev \
libgtk2.0.0 \
libxss1 && \
rm -rf /var/cache/apt/

# Install vs code repo and key
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

# Install dependencies
RUN apt-get update && \
apt-get -y install \
code

# Create developer user and mapp it to host user
# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
mkdir -p /home/developer && \
mkdir -p /etc/sudoers.d && \
echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
echo "developer:x:${uid}:" >> /etc/group && \
echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
chmod 0440 /etc/sudoers.d/developer && \
chown ${uid}:${gid} -R /home/developer && \
export "PULSE_SERVER=unix:/home/developer/pulse/socket"

# Set the new user's home directory
ENV HOME /home/developer

# Copy in the initialization script and allow it to be run by the container user
COPY ./init.sh /home/developer/init.sh
RUN chmod 755 /home/developer/init.sh && \
chown ${uid}:${gid} /home/developer/init.sh

# Switch to the new user
USER developer

WORKDIR /home/developer

# Run initialization script
ENTRYPOINT ["/home/developer/init.sh"]
