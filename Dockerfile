FROM alpine:latest

COPY json2env /usr/local/bin/json2env

RUN set -e -u -o pipefail -x; \
    apk --no-cache update; \
    apk --no-cache upgrade; \
    apk --no-cache add --no-scripts jq; \
    cd /usr/local/bin; \
    echo '#!/bin/sh' >entrypoint.sh; \
    echo '/usr/local/bin/json2env "$@"' >entrypoint.sh; \
    chmod +x json2env entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

