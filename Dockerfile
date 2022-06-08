ARG CHECKOUT=main
ARG VERSION=devbuild

# Node / React container
FROM node:16.14.2-alpine3.15 AS JS_BUILD
ARG CHECKOUT
ARG VERSION

RUN apk fix && \
    apk --no-cache --update add git

RUN mkdir /build
RUN git clone https://github.com/CloudGoBrrr/frontend.git /build/frontend \
    && cd /build/frontend \
    && git checkout $CHECKOUT

WORKDIR /build/frontend

RUN npm install
RUN npm run build

# Go container
FROM golang:1.18.2-alpine3.15 AS GO_BUILD
ARG CHECKOUT
ARG VERSION

RUN apk fix && \
    apk --no-cache --update add git

RUN mkdir /build
RUN git clone https://github.com/CloudGoBrrr/backend.git /build/backend \
    && cd /build/backend \
    && git checkout $CHECKOUT

WORKDIR /build/backend

RUN go build -ldflags="-X 'cloudgobrrr/backend/pkg/env.version=$VERSION'" -o backend-server main.go

# --
# Final Container
FROM alpine:3.15.4
COPY --from=JS_BUILD /build/frontend/build* ./frontend/
COPY --from=GO_BUILD /build/backend/backend-server ./

EXPOSE 8080/tcp
VOLUME ["/data"]

ENV SERVE_PUBLIC=true
ENV PUBLIC_PATH=./frontend

CMD ["./backend-server"]