FROM node:22-alpine AS deps

WORKDIR /app
COPY package.json package.json
COPY package-lock.json package-lock.json
# Build images must follow the lockfile exactly to keep CI and runtime aligned.
RUN npm ci

FROM node:22-alpine AS builder

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:22-alpine AS runner

ENV NODE_ENV=production

WORKDIR /app

RUN addgroup -S app && adduser -S app -G app

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

USER app

EXPOSE 3000

CMD ["node", "server.js"]
