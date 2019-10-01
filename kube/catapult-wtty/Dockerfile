FROM splatform/catapult

ARG TTYD_VERSION=1.5.2
ARG TTYD_OS_TYPE=linux.x86_64
RUN wget https://github.com/tsl0922/ttyd/releases/download/$TTYD_VERSION/ttyd_$TTYD_OS_TYPE -O /usr/bin/ttyd
RUN chmod +x /usr/bin/ttyd
RUN zypper install -y tmux

EXPOSE 8080
WORKDIR /catapult
ENTRYPOINT [ "/usr/bin/ttyd",  "-p" ,"8080", "tmux", "new", "-A", "-s", "catapult", "/usr/bin/make" ]
CMD [ "recover", "terminal" ]
