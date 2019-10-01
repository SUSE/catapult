FROM golang:alpine
RUN apk update && apk add docker
COPY main.go /app/

ENTRYPOINT ["go", "run", "/app/main.go"]