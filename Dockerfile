# syntax=docker/dockerfile:1
ARG NETRUN_DOTNET_SDK_IMAGE=mcr.microsoft.com/dotnet/sdk:10.0.403
ARG NETRUN_DOTNET_RUNTIME_IMAGE=mcr.microsoft.com/dotnet/runtime:10.0

# Без explicit --build-context netrun_core=... COPY завершится отказом, а не pull случайного remote repository.
FROM scratch AS netrun_core

FROM ${NETRUN_DOTNET_SDK_IMAGE} AS netrun-build
ARG NETRUN_CORE_DIGEST
WORKDIR /netrun-core
COPY --from=netrun_core / /netrun-core/
COPY tools/netrun/build-core-container.sh /build-core-container.sh
RUN apt-get update && apt-get install -y --no-install-recommends curl xz-utils \
    && /bin/sh /build-core-container.sh

# .NET 10 остаётся в поддерживаемом runtime image, отдельно от glibc старого BYOND.
FROM ${NETRUN_DOTNET_RUNTIME_IMAGE} AS netrun-host
ARG NETRUN_CORE_DIGEST
WORKDIR /app
COPY --from=netrun-build /netrun-output/host/ ./
COPY --from=netrun-build /netrun-output/source-manifest.json ./source-manifest.json
LABEL org.molot.netrun.source-digest=${NETRUN_CORE_DIGEST}
ENV NETRUN_PORT=18462 NETRUN_SESSION_TOKEN_FILE=/run/secrets/netrun_session_token
USER app
ENTRYPOINT ["dotnet", "Netrun.Host.dll", "serve"]

# base = ubuntu + full apt update
FROM ubuntu:xenial AS base

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates

# byond = base + byond installed globally
FROM base AS byond
WORKDIR /byond

RUN apt-get install -y --no-install-recommends \
        curl \
        unzip \
        make \
        libstdc++6:i386 \
        libcurl3:i386

COPY dependencies.sh .

RUN . ./dependencies.sh \
    && curl "http://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o byond.zip \
    && unzip byond.zip \
    && cd byond \
    && sed -i 's|install:|&\n\tmkdir -p $(MAN_DIR)/man6|' Makefile \
    && make install \
    && chmod 644 /usr/local/byond/man/man6/* \
    && apt-get purge -y --auto-remove curl unzip make \
    && cd .. \
    && rm -rf byond byond.zip

# Официальный Node24 требует glibc>=2.28: TGUI/Juke нельзя запускать в Xenial runtime.
# Установленный BYOND содержит cfg/web/bin/man в /usr/local/byond; shared libraries лежат в bin.
FROM node:24.16.0-bookworm AS build
WORKDIR /tgstation

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6:i386 \
        libstdc++6:i386 \
        libcurl4:i386 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=byond /usr/local/byond/ /usr/local/byond/
ENV BYOND_SYSTEM=/usr/local/byond \
    PATH="/usr/local/byond/bin:${PATH}" \
    LD_LIBRARY_PATH=/usr/local/byond/bin

COPY . .

# Прямой entry point использует pinned Node и не зависит от CRLF/shebang Windows checkout.
# Core строится отдельным stage; deploy сохраняет штатный набор runtime assets.
RUN env NETRUN_CORE_BUILD=0 node tools/build/build.js \
    && /bin/bash tools/deploy.sh /deploy

# rust = base + rustc and i686 target
FROM base AS rust
RUN apt-get install -y --no-install-recommends \
        curl && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
    && ~/.cargo/bin/rustup target add i686-unknown-linux-gnu

# rust_g = base + rust_g compiled to /rust_g
FROM rust AS rust_g
WORKDIR /rust_g

RUN apt-get install -y --no-install-recommends \
        pkg-config:i386 \
        libssl-dev:i386 \
        gcc-multilib \
        git \
    && git init \
    && git remote add origin https://github.com/tgstation/rust-g

COPY dependencies.sh .

RUN . ./dependencies.sh \
    && git fetch --depth 1 origin "${RUST_G_VERSION}" \
    && git checkout FETCH_HEAD \
    && env PKG_CONFIG_ALLOW_CROSS=1 ~/.cargo/bin/cargo build --release --target i686-unknown-linux-gnu

# final = byond + runtime deps + rust_g + build
FROM byond AS netrun-station
ARG NETRUN_CORE_DIGEST
WORKDIR /tgstation

RUN apt-get install -y --no-install-recommends \
        libssl1.0.0:i386 \
        zlib1g:i386

COPY --from=build /deploy ./
COPY --from=rust_g /rust_g/target/i686-unknown-linux-gnu/release/librust_g.so ./librust_g.so
COPY --from=netrun-build /netrun-output/libnetrun_bridge.so ./libnetrun_bridge.so
COPY --from=netrun-build /netrun-output/source-manifest.json ./netrun-core-source.json
COPY tools/netrun/docker-station-entrypoint.sh ./tools/netrun/docker-station-entrypoint.sh
LABEL org.molot.netrun.source-digest=${NETRUN_CORE_DIGEST}
ENV NETRUN_CORE_MODE=external NETRUN_CORE_PORT=18462 \
    NETRUN_CORE_LIBRARY=/tgstation/libnetrun_bridge.so \
    NETRUN_CORE_TOKEN_FILE=/run/secrets/netrun_session_token

VOLUME [ "/tgstation/config", "/tgstation/data" ]
ENTRYPOINT [ "/bin/bash", "/tgstation/tools/netrun/docker-station-entrypoint.sh" ]
CMD [ "tgstation.dmb", "-port", "1337", "-trusted", "-close", "-verbose" ]
EXPOSE 1337
