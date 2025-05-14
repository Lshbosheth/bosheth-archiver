###################
# BUILD FOR LOCAL DEVELOPMENT
###################

FROM node:18-alpine As development

# 创建应用目录
WORKDIR /usr/src/app

# 复制依赖清单到容器镜像里.
COPY --chown=node:node package*.json ./

# 使用npm ci来安装依赖而不是npm install
RUN npm ci

# 复制应用代码到容器中
COPY --chown=node:node . .

# 使用指定的用户而不是root权限用户
USER node

###################
# BUILD FOR PRODUCTION
###################

FROM node:18-alpine As build

WORKDIR /usr/src/app

COPY --chown=node:node package*.json ./

# 我们需要通过Nest CLI 来执行npm run build,这是个开发依赖，然后把安装后依赖全部复制到指定目录
COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules

COPY --chown=node:node . .

RUN npm run build

ENV NODE_ENV production

RUN npm ci --only=production && npm cache clean --force

USER node


FROM node:18-alpine As production

COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build /usr/src/app/dist ./dist

EXPOSE 3000


CMD [ "node", "dist/main.js" ]
