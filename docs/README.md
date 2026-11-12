# 000000book documentation

API and GML references, maintained with the application code.

## Using the API

- [Downloading GML](api/downloading-gml.md), including CORS, rate limits and caching
- [Uploading GML](api/uploading-gml.md), or draw one at [/upload](https://000000book.com/upload)
- [OpenAPI spec](https://000000book.com/openapi.yaml)
- [llms.txt](https://000000book.com/llms.txt), a summary for language models

## Rendering GML

- [Sample playback code](gml/playback-implementations.md), across C++, Processing, Javascript, Flash, PHP and Python
- [canvasplayer](https://github.com/jamiew/canvasplayer), the site's own player, vendored under `public/canvasplayer/`
- [Drawing GML with Javascript and JSON](gml/javascript-and-json.md)
- [PHP API scraping example](examples/php-scraper.md)

## Running it

- [Deployment](deployment.md)
- [Operations](operations.md), including backups, resync and migration rehearsal

## Elsewhere

- Official GML 1.0 spec: graffitimarkuplanguage.com is down; use the
  [2022 snapshot](http://web.archive.org/web/20221225193938/http://graffitimarkuplanguage.com/)
- [GML syntax validator](https://000000book.com/validator)
- [Applications using GML](https://000000book.com/apps)
- [GML mailing list](https://groups.google.com/group/graffiti-markup-language)

## What is GML?

Graffiti Markup Language (`.gml`) is an open XML format for graffiti motion data:
coordinates, timestamps and capture metadata. Applications include
[Graffiti Analysis](http://graffitianalysis.com/) and [EyeWriter](http://eyewriter.org).
See [uploading](api/uploading-gml.md) for the file structure and device pairing.
