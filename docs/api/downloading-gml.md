# Downloading GML

- Every tag page has a "Download GML" button.
- Or append `.gml` to a tag URL, e.g. `https://000000book.com/data/154.gml`.
- `.json` includes metadata and the GML drawing; `.xml` gives metadata only.
  Device credentials are omitted from all three formats. For more on JSON see
  [Drawing GML with Javascript and JSON](../gml/javascript-and-json.md).

Downloads require no API key.

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

Tag and list API responses carry `ETag` and `Last-Modified` validators.
For polling `/latest.gml`, send the previous ETag as `If-None-Match`; an
unchanged response returns `304` with no body. `/random` uses `Cache-Control:
no-store` instead, so a cache does not pin one random result.

```
curl -H 'If-None-Match: "abc123"' https://000000book.com/latest.gml
```

## Preview payload for thumbnails

`/data/:id.json?preview=1` samples the drawing for thumbnails: a target of
300 points, with every stroke's endpoints retained, so the count can exceed 300.
Coordinates use three decimal places and time uses two; per-stroke styling is
omitted. The site's grid and filmstrip use this payload.

```
curl 'https://000000book.com/data/147.json?preview=1'
```

```json
{ "id": 147, "app": "DustTag", "up": { "x": 1.0, "y": 0.0 }, "rotate": true,
  "strokes": [ { "points": [[0.427, 0.113, 0.0], [0.431, 0.118, 0.03]] } ] }
```

`up` is the capture's up vector; `rotate` is the server's rotation decision for
older clients. Preview, player and ordinary JSON responses have separate ETags.

`?player=1` returns all usable points, with coordinates rounded to five decimal
places and time to four. It includes per-stroke colour, brush and drip settings,
plus screen bounds and client name. This is normalized playback data, not a
lossless copy: points without numeric x/y are skipped and missing time becomes
zero. Use `.gml` or ordinary `.json` for the original drawing fields.

Ordinary JSON and XML metadata include `views_count`: page loads, `.gml`
downloads and player-payload loads. Preview requests and `304` responses do not
count. View increments do not change the ETag, so a cached count can be stale.

## Other handy API access points

Latest tag uploaded site-wide:

```
curl https://000000book.com/latest.gml
```

A random tag:

```
curl https://000000book.com/random.gml
```

Tags by a specific application:

```
curl 'https://000000book.com/data.json?app=eyewriter'
```

Tags from one anonymous device, using the codename shown on its tags:

```
curl 'https://000000book.com/data.json?user=anon-1a2b3'
```

Results are newest first. Use `page` and `per_page` (default 15, maximum 100)
to paginate. Only one search field is used, in this precedence order: `app`,
`user`, `location`, `keywords`, `user_id`. The `user` field matches the anonymous
device codename, not an account login; `user_id` accepts an account login or ID.

Additional filters combine with that search: `has=still`, `from=device`,
`who=claimed` or `who=anon`, and `year=2010`. `who` checks account ownership;
`from=device` checks for a device key.

`/latest` and `/random` ignore filters. To find an application's newest tag,
use `/data.json?app=eyewriter&per_page=1`.
