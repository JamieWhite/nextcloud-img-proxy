# nextcloud-img-proxy

This creates an API that proxies the nextcloud API. This turns what is several nextcloud requests to upload and share an image into one. Any images you upload to this API will be renamed to `IMG_DATE.jpeg`. I guess this means it only supports jpegs 😄

# How to run

Copy this into `docker-compose.yml` into its own folder. then run `docker-compose up -d`

```
version: '3.7'

x-shared_environment: &shared_environment
  LOG_LEVEL: ${LOG_LEVEL:-debug}
  
services:
  app:
    image: jamiewhite/nextcloud-img-proxy:latest
    restart: always
    environment:
      <<: *shared_environment
    ports:
      - '45315:8080'
```

You can change the exposed port from 45315 to anything you want. You need to keep the internal port as 8080 however

# the API

The API exposes 1 route: `http://host/upload-image` which has `upload-image/{nextcloud token}/{nextcloud username}/{folder}`

## Parameters:

`nextcloud token` = The app token you generate in the nextcloud web UI under the security settings. You can also use your main password.

`nextcloud username` = The nextcloud username.

`folder` = the folder where images will be uploaded. You might have to create this folder first. I'm not sure if nested folders work so you might have to create a top level folder.

# Use cases 

1. You can use this in an iOS or Mac shortcut to share images from a folder/camera roll/etc
