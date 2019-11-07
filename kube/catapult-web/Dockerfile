FROM splatform/catapult
#FROM golang:alpine
#RUN apk update && apk add docker
ENV TTY_IMAGE=catapult-wtty
COPY main.go /app/

ENTRYPOINT ["go", "run", "/app/main.go"]