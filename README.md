# Nextcloud image proxy

A small Vapor app that uploads a JPEG to Nextcloud and returns its public image URL.

## Development

Use Swift 6.4 (Swift 6 language mode) or newer. macOS 13 is the minimum deployment target; Linux is supported through Docker. Dependencies are pinned in `Package.resolved`.

```sh
swift build
swift test
NEXTCLOUD_DOMAIN=cloud.example.com SHARE_DOMAIN=img.example.com swift run App serve --hostname 127.0.0.1 --port 8080
```

The layout follows the Vapor 4 template: a single executable target, an async `@main` entrypoint, `configure.swift`, `routes.swift`, route controllers, and Swift Testing with VaporTesting. Vapor 4.122.3 is the stable baseline at this update; Vapor 5 is still in beta.

## API

- `GET /upload-image` returns an example upload URL.
- `PUT /upload-image/:token/:username/:folder` accepts raw JPEG bytes, up to 40 MB, and returns the shared image URL as plain text.
- The PUT route also accepts one trailing filename segment, which is ignored for compatibility. The server generates the filename.

The Nextcloud and image domains are required environment variables: `NEXTCLOUD_DOMAIN` and `SHARE_DOMAIN`. The app fails at startup if either is missing or empty. Defaults are supplied only by Docker Compose. Supply hostnames only, without `https://` or paths; the app uses HTTPS. The token is passed to Nextcloud as bearer authorization. Because the existing API carries credentials in its URL, serve it over HTTPS and avoid storing request paths in proxy access logs.

## Deploy a published image

For a Raspberry Pi running a 64-bit OS, save this as `compose.yaml`:

```yaml
services:
  app:
    image: jamiewhite/nextcloud-img-proxy:latest
    platform: linux/arm64
    restart: unless-stopped
    ports:
      - "45315:8080"
    environment:
      LOG_LEVEL: info
      NEXTCLOUD_DOMAIN: ${NEXTCLOUD_DOMAIN:?Set NEXTCLOUD_DOMAIN in .env}
      SHARE_DOMAIN: ${SHARE_DOMAIN:?Set SHARE_DOMAIN in .env}
```

Create `.env` alongside it with your `NEXTCLOUD_DOMAIN` and `SHARE_DOMAIN` hostnames, then run:

```sh
docker compose pull app
docker compose up -d app
```

The host port `45315` can be changed; the container listens on port `8080`.

Generate the Nextcloud app token in your account's security settings. Use your Nextcloud username and an existing top-level destination folder in the upload URL. An iOS or macOS Shortcut can convert a photo to JPEG, upload it, and copy the returned link for sharing.

The release workflow in `.github/workflows/docker-image.yml` publishes AMD64 and ARM64 images to Docker Hub when a GitHub release is published. It uses the repository secrets `DOCKER_USERNAME` and `DOCKER_PASSWORD`.

## Build locally with Docker

```sh
docker compose build
docker compose up app
```

Override the domains in your shell or a local `.env` file (Compose passes them into the container):

```dotenv
NEXTCLOUD_DOMAIN=cloud.example.com
SHARE_DOMAIN=img.example.com
```

Then run `docker compose up --build app`. For local Swift runs, export the same environment variables in your shell.

The Dockerfile follows the current Vapor template with Swift 6.4 on Ubuntu Noble, a non-root runtime user, jemalloc, and the Swift crash reporter. It runs the `App` executable on port 8080. The old `Run` target has been removed; update any external scripts that invoke it.

## Updating

```sh
swift package update
swift test
```

Commit the updated lockfile with dependency changes. The tests use in-process requests and do not require Nextcloud credentials.
