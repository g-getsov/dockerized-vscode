FROM debian:buster-slim

# Add buster non free and contrib source list
RUN echo "deb http://ftp.ua.debian.org/debian buster contrib non-free" | tee -a /etc/apt/sources.list.d/docker.list && \
echo "deb-src http://ftp.ua.debian.org/debian buster contrib non-free" | tee -a /etc/apt/sources.list.d/docker.list

# Disable terminal prompt interaction during setup
ENV DEBIAN_FRONTEND=noninteractive 

# Setup the Rust and Cargo paths
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

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

# Install rust (this has been copied over from the official rust docker image and needs to be updated for newer versions when needed)
RUN set -eux; \
    \
# this "case" statement is generated via "update.sh"
    dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
		amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='c9837990bce0faab4f6f52604311a19bb8d2cde989bea6a7b605c8e526db6f02' ;; \
		armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='297661e121048db3906f8c964999f765b4f6848632c0c2cfb6a1e93d99440732' ;; \
		arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='a68ac2d400409f485cb22756f0b3217b95449884e1ea6fd9b70522b3c0a929b2' ;; \
		i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='27e6109c7b537b92a6c2d45ac941d959606ca26ec501d86085d651892a55d849' ;; \
		*) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
	esac; \
    \
    url="https://static.rust-lang.org/rustup/archive/1.11.0/${rustArch}/rustup-init"; \
    curl "$url" -s -o rustup-init; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --default-toolchain 1.24.1; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

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

# Setup the Rust and Cargo paths
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

WORKDIR /home/developer

# Run initialization script
ENTRYPOINT ["/home/developer/init.sh"]
