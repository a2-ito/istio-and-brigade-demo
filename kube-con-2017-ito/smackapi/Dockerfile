FROM golang

ADD ./smackapi/*.go /app/
RUN cd /app && go get github.com/gorilla/mux && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o smackapi

FROM alpine

ARG VCS_REF
ARG BUILD_DATE
ARG IMAGE_TAG_REF

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.name="Microsmack API app" \
      org.label-schema.description="Simple golang web api for use in Kubernetes demos" \
      org.label-schema.vcs-url="https://github.com/chzbrgr71/microsmack" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/smackapi/Dockerfile"

ENV GIT_SHA $VCS_REF
ENV IMAGE_BUILD_DATE $BUILD_DATE
ENV IMAGE_TAG $IMAGE_TAG_REF

WORKDIR /app
#ADD ./smackapi /app/
COPY --from=0 /app/smackapi /app/

ENTRYPOINT /app/smackapi
EXPOSE 8081
