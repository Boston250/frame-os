FROM node:22-alpine AS build
WORKDIR /app
ENV NEXT_PUBLIC_FRAME_API_MODE=live
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV KPI_DOCUMENT_DIRECTORY=/var/lib/frame/kpi-documents
COPY --from=build /app ./
RUN mkdir -p /var/lib/frame/exports /var/lib/frame/kpi-documents
EXPOSE 3000
CMD ["npm","run","start"]
