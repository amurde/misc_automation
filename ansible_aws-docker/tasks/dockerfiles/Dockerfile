FROM nginx:stable-alpine

WORKDIR app
EXPOSE 8443

# SSL configuration
RUN mkdir -p /etc/nginx/certs

RUN apk add --no-cache openssl

RUN openssl genrsa -des3 -passout pass:onlyfortesting -out server.withpass.key 2048 && \
    openssl rsa -passin pass:onlyfortesting -in server.withpass.key -out /etc/nginx/certs/default.key && \
    rm server.withpass.key && \
    openssl req -new -key /etc/nginx/certs/default.key -out server.csr \
    -subj "/C=EE/ST=Tartumaa/L=Tartu/O=OrgName/OU=IT Department/CN=test.local" && \
    openssl x509 -req -days 90  -in server.csr -signkey /etc/nginx/certs/default.key -out /etc/nginx/certs/default.crt

COPY default.conf /etc/nginx/conf.d/
