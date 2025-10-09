# ---- Stage 1: Build environment ----
FROM node:16 AS build
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --omit=dev || npm install --only=production
COPY . .

# ---- Stage 2: Runtime environment ----
FROM node:16-alpine
WORKDIR /usr/src/app
COPY --from=build /usr/src/app .
EXPOSE 8080
CMD ["npm", "start"]
