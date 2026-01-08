FROM node:22.21.0
ARG APP_PATH
ARG SRC_PATH
ARG CDN_URL
WORKDIR $APP_PATH
COPY ${SRC_PATH}/package.json ${SRC_PATH}/yarn.lock ${SRC_PATH}/.yarnrc.yml ./
COPY ${SRC_PATH}/patches ./patches
ENV NODE_OPTIONS='--max-old-space-size=24000'
RUN corepack enable && \
    yarn install --immutable --network-timeout 1000000 && \
    yarn cache clean
COPY ${SRC_PATH} .
COPY ./patches/* .
RUN for patch in $(ls *.patch); do patch -p1 < $patch; done
RUN cat << EOF > /entrypoint.sh
npx yarn concurrently -n "dev,i18n" \
    "yarn dev:watch" \
    "yarn nodemon \
        --watch './shared/i18n/locales/ru_RU' \
        --exec 'yarn build:i18n'"
EOF
ENV DATA_PATH=/var/lib/outline/data
VOLUME ${DATA_PATH}
STOPSIGNAL SIGKILL
ENTRYPOINT ["bash", "/entrypoint.sh"]
