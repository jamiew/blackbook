# 000000book documentation

Imported from the [GitHub wiki](https://github.com/jamiew/blackbook/wiki) so it
lives with the code, can be reviewed in pull requests, and is available to both
the website and anyone (or anything) working on the repo.

## Using the API

- [Downloading GML](api/downloading-gml.md), including CORS, rate limits and caching
- [Uploading GML](api/uploading-gml.md), or draw one at [/upload](http://000000book.com/upload)
- [OpenAPI spec](http://000000book.com/openapi.yaml), the same thing machine-readable
- [llms.txt](http://000000book.com/llms.txt), a summary for language models

## Rendering GML

- [Sample playback code](gml/playback-implementations.md), across C++, Processing, Javascript, Flash, PHP and Python
- [canvasplayer](https://github.com/jamiew/canvasplayer), the site's own player, vendored under `public/canvasplayer/`
- [Drawing GML with Javascript and JSON](gml/javascript-and-json.md)
- [PHP API scraping example](examples/php-scraper.md)

## Running it

- [Deployment](deployment.md)
- [Operations](operations.md), including backups, resync and migration rehearsal

## Elsewhere

- Official GML 1.0 spec — graffitimarkuplanguage.com is down; use the
  [2022 snapshot](http://web.archive.org/web/20221225193938/http://graffitimarkuplanguage.com/)
- [GML syntax validator](http://000000book.com/validator)
- [Applications using GML](http://000000book.com/apps)
- [GML mailing list](http://groups.google.com/group/graffiti-markup-language)

## What is GML?

Graffiti Markup Language (`.gml`) is a universal, XML-based, open file format for
storing graffiti motion data: x and y coordinates and time. The format is designed
to maximize readability and ease of implementation, even for hobbyist programmers,
artists and graffiti writers. Applications implementing GML include
[Graffiti Analysis](http://graffitianalysis.com/) and [EyeWriter](http://eyewriter.org).

Beyond storing data, a main goal of GML is to spark interest in the importance
(and fun) of open data, and to introduce open source collaboration to new
communities. GML is intended as a simple bridge between ink and code.

## Gaps

The wiki linked two pages that were never written, so they did not come across:

- **Device Pairing** — how uniqueKeys link an app's uploads to a 000000book user.
  Referenced from the old wiki home and from [Uploading GML](api/uploading-gml.md).
- **GML Minimum Specs** — the required fields an upload is validated against.
  Referenced from [Uploading GML](api/uploading-gml.md).
