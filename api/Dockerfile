FROM node:24-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssl python3 make g++ \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /api

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
ENV DATABASE_URL=file:./database.db
RUN npx prisma generate

EXPOSE 3333
CMD ["sh", "-c", "npx prisma migrate deploy && npx tsx src/server.ts"]
