FROM debian:buster-slim as svencoop

ENV USER steam
ENV HOME "/home/${USER}"
ENV STEAMCMDDIR "${HOME}/steamcmd"
ENV GAME_DIR "svencoop"
ENV GAME_PATH "${HOME}/${GAME_DIR}"

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

ARG PUID=1000
ENV USER steam
ENV HOME "/home/${USER}"
ENV STEAMCMDDIR "${HOME}/steamcmd"
ENV STEAM_APPID 276060
ENV GAME_DIR "svencoop"
ENV GAME_PATH "${HOME}/${GAME_DIR}"

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

RUN useradd -u "${PUID}" -m "${USER}"

COPY --chown=${PUID}:${PUID} --from=svencoop ${HOME} ${HOME}
COPY --chown=${PUID}:${PUID} etc/server.cfg ${GAME_PATH}/${GAME_DIR}/server.cfg

RUN mkdir -p "${HOME}/.steam/sdk32" \
	&& ln -s "${STEAMCMDDIR}/linux32/steamclient.so" "${HOME}/.steam/sdk32/steamclient.so" \
	&& ln -s "${STEAMCMDDIR}/linux32/steamcmd" "${STEAMCMDDIR}/linux32/steam" \
	&& ln -s "${STEAMCMDDIR}/steamcmd.sh" "${STEAMCMDDIR}/steam.sh"

USER ${USER}

WORKDIR ${GAME_PATH}

ENV GAME_MAP "osprey"
ENV GAME_MAXPLAYERS 32
ENV GAME_ARGS "+maxplayers ${GAME_MAXPLAYERS} +map ${GAME_MAP} +log on"
# ENV LD_LIBRARY_PATH "${GAME_PATH}/bin:${GAME_PATH}/bin/linux32"

CMD ${GAME_PATH}/svends_run -console -port 27016 ${GAME_ARGS}

# Expose ports
EXPOSE 27016/tcp
EXPOSE 27016/udp
# VAC
EXPOSE 26900/udp