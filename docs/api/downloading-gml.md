# Downloading GML

- Every tag page has a "Download GML" button.
- Or append `.gml` to any data page URL, e.g. `http://000000book.com/data/154.gml`
- Other formats work too: `.json` includes the full GML as JSON, and `.xml` gives
  metadata only. For more on JSON (GSON) see
  [Drawing GML with Javascript and JSON](../gml/javascript-and-json.md).

There is no API key and none is needed. Everything here is public.

## Loading it from a browser

Every endpoint below allows cross-origin requests from any origin, so `fetch()`
works from your own page:

```js
const res = await fetch('https://000000book.com/data/154.json')
const tag = await res.json()
console.log(tag.gml)
```

JSONP still works too. Add `?callback=yourFunction` to any `.json` URL and you
get `/**/yourFunction({...})` back. Prefer CORS in new code: JSONP cannot report
errors and runs whatever we send as script.

The machine-readable description of all of this is
[/openapi.yaml](https://000000book.com/openapi.yaml), with a summary for language
models at [/llms.txt](https://000000book.com/llms.txt).

## Being polite

Reads are limited to 300 requests a minute per IP address, uploads to 30 an hour.
Over the limit you get a `429` and a `Retry-After` header saying how long to wait.

Responses carry `ETag` and `Last-Modified`. If you are polling `/latest.gml`, send
the ETag back as `If-None-Match` and you will get an empty `304` until something
actually changes:

```
curl -H 'If-None-Match: "abc123"' http://000000book.com/latest.gml
```

## Preview payload for thumbnails

`/data/:id.json?preview=1` returns the tag cut down for drawing small: about
300 points, three decimal places, no per-stroke styling. The site's own grid
and filmstrip draw from it.

```
curl 'http://000000book.com/data/147.json?preview=1'
```

```json
{ "id": 147, "app": "DustTag", "up": { "x": 1.0, "y": 0.0 }, "rotate": true,
  "strokes": [ { "points": [[0.427, 0.113, 0.0], [0.431, 0.118, 0.03]] } ] }
```

`up` is the capture's up vector, so a client can decide rotation the way the
reference player does; `rotate` is the server's answer for older clients. It
carries the same ETag and caching rules as the full `.json`.

`?player=1` is the same shape at full fidelity, every point with its
per-stroke colour and brush: what the site inlines for its own player.

Every tag carries `views_count`: how many times its page, its `.gml` or its
player payload has been loaded. Thumbnails and cache hits do not count.

## Other handy API access points

Latest tag uploaded site-wide:

```
curl http://000000book.com/latest.gml
```

A random tag:

```
curl http://000000book.com/random.gml
```

Tags by a specific application:

```
curl 'http://000000book.com/data.json?app=eyewriter'
```

Tags from one anonymous device, using the codename shown on its tags:

```
curl 'http://000000book.com/data.json?user=anon-1a2b3'
```

Filtering also works on `location` and `keywords`, and pages with `page` and
`per_page` (default 15, maximum 100). The chips on `/data` are plain
parameters too and combine: `has=still`, `from=device`, `who=claimed` or
`who=anon`, and `year=2010`.

Note that `/latest` and `/random` take no filters: they are the newest and a
random tag across the whole archive. Earlier versions of this page documented
`/latest.gml?application=eyewriter` and `/tempt1/latest.gml`; neither has ever
worked. Use `/data.json?app=` as above.
