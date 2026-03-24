ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION} AS base

RUN apk add --no-cache nodejs npm

WORKDIR /app

COPY tools/app/package*.json ./

FROM base AS prod-deps

RUN npm install --omit=dev

FROM base AS build-deps

RUN npm install

FROM build-deps AS build
COPY /tools/app/ ./
RUN npm run build


FROM base AS runtime
RUN apk add --no-cache curl
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

ENV HOST=0.0.0.0
ENV PORT=4321
EXPOSE 4321

CMD ["node", "dist/server/entry.mjs"]
