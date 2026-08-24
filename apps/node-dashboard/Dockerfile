# Multi-stage build for the workshop sample application.
#
# Two things about this file are deliberate and are teaching material rather
# than accidents. Read the "Container image" section of README.md before
# changing either of them.
#
#   1. The build stage and the runtime stage use DIFFERENT base images. The
#      build stage is current. The runtime stage is old and carries known
#      operating system level vulnerabilities.
#   2. The runtime stage carries no toolchain, no npm cache and no build
#      dependencies. Only the resolved node_modules and the application source.

# ---------------------------------------------------------------- build stage

FROM node:20-bookworm-slim AS build

WORKDIR /app

# Copy manifests first so this layer caches independently of source changes.
# npm ci requires package-lock.json to be present and in sync with
# package.json. If the build fails here with a lock file error, the lock file
# has not been generated yet: see "Generating the lock file" in README.md.
COPY package.json package-lock.json ./

# --omit=dev because nothing in devDependencies is needed at runtime.
# --no-audit because this application ships known-vulnerable dependencies on
# purpose and npm's own audit summary would preempt the labs that reveal them.
# The workshop uses "jf audit" instead.
RUN npm ci --omit=dev --no-audit --no-fund

COPY src ./src

# -------------------------------------------------------------- runtime stage

# Pinned to an exact patch, and pinned deliberately old.
#
# This image is the second layer of the workshop's vulnerability story. The
# attendee remediates the application's npm dependencies during the earlier
# labs and the build goes green. The findings that remain in the built image
# come from this line, and from nothing the attendee wrote. That is the point
# being made in lab 07.
#
# Do not upgrade this. See CONTRIBUTING.md.
FROM node:16.20.2-bullseye-slim AS runtime

WORKDIR /app

ENV NODE_ENV=production \
    PORT=3000

# Every dependency in this application is pure JavaScript, so node_modules
# resolved by the build stage's newer npm is safe to run on this older Node.
# If a dependency with a native addon is ever added, this copy stops being
# valid and the install has to move into the runtime stage.
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/src ./src
COPY package.json ./

# Drop root. The node images ship an unprivileged "node" user.
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/healthz',function(r){process.exit(r.statusCode===200?0:1)}).on('error',function(){process.exit(1)})"

CMD ["node", "src/index.js"]
