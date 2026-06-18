# syntax=docker/dockerfile:1

# Imagen del target WEB de atmosphere-app: build de Flutter web servido por nginx
# (ADR-004: atmosphere-web = contenedor nginx; desktop = binarios nativos, NO
# contenerizados). Los docker-compose son de S-003, no de esta story.

# ---- builder ----------------------------------------------------------------
# Toolchain Flutter pineada (sin :latest). El SDK local es 3.44.1, pero
# cirruslabs no publica imagen prebuilt para ese parche; 3.44.0 es la última
# stable publicada del mismo minor y satisface el constraint de pubspec
# (Dart >=3.12.0 <4.0.0). Se fija a 3.44.0 para que la imagen sea pulleable.
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS builder

WORKDIR /app

# Cachear la resolución de dependencias: copiar manifests y resolver antes que
# el código, para que un cambio sólo de código no rebaje el caché.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# API_BASE_URL se inyecta en build-time (no hardcodeada). flutter_dotenv lee el
# `.env` bundleado como asset; lo generamos acá desde el build-arg para mantener
# coherencia con la estrategia env-config de la app (la web NUNCA asume mismo
# origen: la base URL siempre viene de config).
ARG API_BASE_URL=http://localhost:8080
RUN echo "API_BASE_URL=${API_BASE_URL}" > .env

RUN flutter build web --release

# ---- runtime ----------------------------------------------------------------
# nginx estable y delgado (pineado, sin :latest) sirviendo el build estático.
FROM nginx:1.27-alpine AS runtime

# Config de nginx con fallback SPA (go_router en web usa rutas por URL).
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

# nginx:alpine ya define el CMD por defecto (nginx -g 'daemon off;').
