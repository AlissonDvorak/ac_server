FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV STEAMCMD_DIR=/steamcmd
ENV SERVER_DIR=/ac-server

# Enable 32-bit architecture
RUN dpkg --add-architecture i386

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    lib32gcc-s1 \
    wine \
    wine32 \
    wine64 \
    libwine \
    libwine:i386 \
    fonts-wine \
    xvfb \
    cabextract \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate Locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install SteamCMD
RUN mkdir -p ${STEAMCMD_DIR} && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C ${STEAMCMD_DIR}

# Create user and dirs
RUN useradd -m -d /home/acserver -s /bin/bash acserver && \
    mkdir -p ${SERVER_DIR} && \
    chown -R acserver:acserver ${STEAMCMD_DIR} ${SERVER_DIR}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER acserver
WORKDIR ${SERVER_DIR}

EXPOSE 9600/tcp 9600/udp 8081/tcp

CMD ["/entrypoint.sh"]
