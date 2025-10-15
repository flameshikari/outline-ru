FROM node:22 AS base
ARG APP_PATH
ARG SRC_PATH
WORKDIR $APP_PATH

FROM base AS deps
COPY ${SRC_PATH}/package.json ${SRC_PATH}/yarn.lock ./
RUN yarn install --production=true --frozen-lockfile --network-timeout 1000000 && \
    yarn cache clean

FROM base AS build
RUN apt-get update && \
    apt-get install -y patch cmake && \
    rm -rf /var/lib/apt/lists/*
COPY ${SRC_PATH}/patches ./patches
COPY ${SRC_PATH}/package.json ${SRC_PATH}/yarn.lock ./
ENV NODE_OPTIONS="--max-old-space-size=24000"
RUN yarn install --no-optional --frozen-lockfile --network-timeout 1000000 && \
    yarn cache clean
COPY ${SRC_PATH} .
COPY --from=deps  $APP_PATH/node_modules ./node_modules
COPY ./tools/patches/* .
RUN for patch in $(ls *.patch); do patch -p1 < $patch; done
RUN cat <<EOF > /entrypoint.sh
npx yarn concurrently -n "dev,i18n" \
    "yarn dev:watch" \
    "yarn nodemon \
        --watch './shared/i18n/locales/ru_RU' \
        --exec 'yarn build:i18n'"
EOF
ARG CDN_URL
ARG DATA_PATH=/var/lib/outline/data
VOLUME ${DATA_PATH}
STOPSIGNAL SIGKILL
ENTRYPOINT ["bash", "/entrypoint.sh"]
