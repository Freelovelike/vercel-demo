# syntax=docker/dockerfile:1

# 1) Base image
FROM node:20-alpine AS base
WORKDIR /app
ENV NODE_ENV=production

# 2) Dependencies stage
FROM base AS deps
# Install libc6-compat for some native deps
RUN apk add --no-cache libc6-compat
COPY package.json package-lock.json* .npmrc* ./
RUN npm ci --no-audit --no-fund

# 3) Build stage
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# 4) Runtime stage
FROM base AS runtime
ENV PORT=3000
EXPOSE 3000
# Run as non-root user when possible
RUN addgroup -S app && adduser -S app -G app
USER app
WORKDIR /app
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules

CMD ["npx", "next", "start", "-p", "3000"]