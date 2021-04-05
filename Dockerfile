FROM debian:buster-slim

ARG PUID=1000

ENV USER steam
ENV HOME "/home/${USER}"
ENV STEAMCMDDIR "${HOME}/steamcmd"
ENV STEAM_APPID 276060

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
		wget \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	&& useradd -u "${PUID}" -m "${USER}" \
	&& mkdir -p "${STEAMCMDDIR}" \
	&& wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C "${STEAMCMDDIR}" \
	&& chown -R 1000:1000 "${HOME}" \
	&& apt-get remove --purge -y \
		wget \
	&& apt-get autoremove -y \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/*


USER ${USER}

WORKDIR ${HOME}

ENV GAME_DIR "svencoop"
ENV GAME_PATH "${HOME}/${GAME_DIR}"

RUN mkdir -p "${GAME_PATH}" \
	&& mkdir -p "${HOME}/.steam/sdk32" \
	&& ln -s "${STEAMCMDDIR}/linux32/steamclient.so" "${HOME}/.steam/sdk32/steamclient.so" \
	&& ln -s "${STEAMCMDDIR}/linux32/steamcmd" "${STEAMCMDDIR}/linux32/steam" \
	&& ln -s "${STEAMCMDDIR}/steamcmd.sh" "${STEAMCMDDIR}/steam.sh" \
	&& "${HOME}/steamcmd/steamcmd.sh" \
		+login anonymous \
		+force_install_dir "${GAME_PATH}" \
		+app_update ${STEAM_APPID} \
		+quit

COPY etc/server.cfg ${GAME_PATH}/${GAME_DIR}/server.cfg

WORKDIR ${GAME_PATH}

ENV GAME_MAP "osprey"
ENV GAME_MAXPLAYERS 32
ENV GAME_ARGS "+maxplayers ${GAME_MAXPLAYERS} +map ${GAME_MAP} +log on"
ENV LD_LIBRARY_PATH "${GAME_PATH}/bin:${GAME_PATH}/bin/linux32"

CMD ${GAME_PATH}/svends_run -console -port 27016 ${GAME_ARGS}

# Expose ports
EXPOSE 27016/tcp
EXPOSE 27016/udp
# VAC
EXPOSE 26900/udp