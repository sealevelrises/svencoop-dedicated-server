FROM debian:buster-slim as svencoop

ARG USER=steam
ARG HOME="/home/${USER}"
ARG STEAMCMDDIR="${HOME}/steamcmd"
ARG GAME_DIR="svencoop"
ARG GAME_PATH="${HOME}/${GAME_DIR}"

RUN set -x \
	&& dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		ca-certificates \
		locales \
		wget \
		unzip \
		libsdl2-2.0-0:i386

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales

# Install SteamCmd
RUN mkdir -p "${STEAMCMDDIR}" \
	&& mkdir -p "${GAME_PATH}/${GAME_DIR}" \
	&& mkdir -p "${GAME_PATH}/steamapps" \
	&& wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C "${STEAMCMDDIR}"

# Install Sven Coop
RUN "${STEAMCMDDIR}/steamcmd.sh" \
		+force_install_dir "${GAME_PATH}" \
		+login anonymous \
		+app_update 276060 \
		+quit

FROM debian:buster-slim

RUN set -x \
	&& dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		lib32stdc++6 \
		lib32gcc1 \
		libssl1.1:i386 \
		zlib1g:i386 \
		libsdl2-2.0-0:i386 \
		libncurses5:i386 \
		ca-certificates \
		locales \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& apt-get autoremove -y \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/*

ARG PUID=1000
ARG USER=steam
ARG HOME="/home/${USER}"
ARG STEAMCMDDIR="${HOME}/steamcmd"
ARG GAME_DIR="svencoop"
ARG GAME_PATH="${HOME}/${GAME_DIR}"

RUN useradd -u "${PUID}" -m "${USER}"

COPY --chown=${PUID}:${PUID} --from=svencoop ${HOME} ${HOME}
COPY --chown=${PUID}:${PUID} etc/server.cfg ${GAME_PATH}/${GAME_DIR}/server.cfg

RUN mkdir -p "${HOME}/.steam/sdk32" \
	&& ln -s "${STEAMCMDDIR}/linux32/steamclient.so" "${HOME}/.steam/sdk32/steamclient.so" \
	&& ln -s "${STEAMCMDDIR}/linux32/steamcmd" "${STEAMCMDDIR}/linux32/steam" \
	&& ln -s "${STEAMCMDDIR}/steamcmd.sh" "${STEAMCMDDIR}/steam.sh"

USER ${USER}

WORKDIR ${GAME_PATH}

ARG GAME_PORT=27016
ARG GAME_MAXPLAYERS=32
ARG GAME_MAP="_server_start"

ENV GAME_PORT=${GAME_PORT}
ENV GAME_MAXPLAYERS=${GAME_MAXPLAYERS}
ENV GAME_MAP=${GAME_MAP}
ENV GAME_ARGS="+maxplayers ${GAME_MAXPLAYERS} +map ${GAME_MAP} +log on"

CMD ./svends_run -console -port ${GAME_PORT} ${GAME_ARGS}

# Expose ports
EXPOSE ${GAME_PORT}/tcp
EXPOSE ${GAME_PORT}/udp
# VAC
EXPOSE 26900/udp