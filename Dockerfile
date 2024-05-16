# First stage of the build is to install dependencies, and build from source......
FROM registry.access.redhat.com/ubi8/nodejs-18 as build

WORKDIR /usr/src/app
COPY --chown=1001:1001 chart ./
COPY --chown=1001:1001 package*.json ./
RUN npm ci
COPY --chown=1001:1001 tsconfig*.json ./
COPY --chown=1001:1001 src src
RUN npm run build:ts

# Second stage of the build is to create a lighter container with just enough
# required to run the application, i.e production deps and compiled js files
FROM registry.access.redhat.com/ubi8/nodejs-18
WORKDIR /usr/src/app

COPY --chown=1001:1001 --from=build /usr/src/app/package*.json/ .
COPY --chown=1001:1001 --from=build /usr/src/app/chart .
RUN npm ci --omit=dev
COPY --chown=1001:1001 --from=build /usr/src/app/dist/ dist/

ENV NODE_ENV=production
ENV FASTIFY_PORT 8080
ENV FASTIFY_ADDRESS 0.0.0.0
EXPOSE 8080

ENTRYPOINT [ "./node_modules/.bin/fastify" ]
CMD [ "start", "-l", "info", "dist/app.js" ]