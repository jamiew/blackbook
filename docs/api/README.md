# The 000000book API

GML goes in and out over plain HTTP. There is no key to request and no SDK to
install: uploading needs a POST, and every tag is downloadable as GML, JSON or
XML by appending an extension to its URL.

- [Downloading GML](downloading-gml.md) — per-tag formats, `/latest`, `/random`
  and the filters the index accepts
- [Uploading GML](uploading-gml.md) — the POST payload, the optional metadata
  fields, and how device pairing uses `uniqueKey`

## Quick reference

| | |
|---|---|
| One tag | `/data/154.gml`, `.json` or `.xml` |
| Newest tag site-wide | `/latest.gml` |
| A random tag | `/random.gml` |
| Filtered list | `/data.json?app=eyewriter`, also `user_id`, `location`, `keywords` |
| Upload | `POST /data` with a `gml` parameter |

Rendering what you download is covered in
[sample playback code](../gml/playback-implementations.md), which collects
community implementations across C++, Processing, Javascript, PHP and Python.
