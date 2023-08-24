FROM node:18-alpine AS dependencies
WORKDIR /workspace
# COPY package.json yarn.lock ./
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
# RUN yarn
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi
FROM node:18-alpine AS build
WORKDIR /workspace
COPY --from=dependencies /workspace/node_modules ./node_modules
COPY . .
RUN npx prisma generate
RUN yarn run build

FROM node:18-alpine AS deploy
ENV NODE_ENV production
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

WORKDIR /workspace
COPY --from=build /workspace/public ./public
COPY --from=build --chown=nextjs:nodejs /workspace/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /workspace/.next/static ./.next/static
# COPY --from=build /workspace/.next/standalone ./
# COPY --from=build /workspace/.next/static ./.next/static
USER nextjs

EXPOSE 3000
ENV PORT 3000
# CMD ["npm","run", "start"]
# CMD ["yarn", "start"]
CMD ["node", "server.js"]