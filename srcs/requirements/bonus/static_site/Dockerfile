ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
# ==========================================
# Stage 1: Base
# ==========================================
FROM alpine:${ALPINE_VERSION} AS base

RUN apk add --no-cache nodejs npm

WORKDIR /app

COPY tools/app/package*.json ./

# ==========================================
# Stage 2: Production dependencies
# ==========================================
FROM base AS prod-deps

RUN npm install --omit=dev

# ==========================================
# Stage 3: Build dependencies
# ==========================================
FROM base AS build-deps

RUN npm install

# ==========================================
# Stage 4: Compilation (Build)
# ==========================================
FROM build-deps AS build

COPY tools/app/ ./
RUN npm run build

# ==========================================
# Stage 5: Runtime
# ==========================================
FROM base AS runtime

RUN apk add --no-cache curl

RUN addgroup -S astroup && adduser -S astrouser -G astroup

COPY --chown=astrouser:astroup --from=prod-deps /app/node_modules ./node_modules
COPY --chown=astrouser:astroup --from=build /app/dist ./dist

ENV HOST=0.0.0.0
ENV PORT=4321
EXPOSE 4321

CMD ["node", "dist/server/entry.mjs"]
