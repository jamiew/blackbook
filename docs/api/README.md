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
| Filtered list | `/data.json?app=eyewriter`, also `user`, `location`, `keywords`, `has=still`, `who=anon`, `year=2010` |
| For drawing | `/data/154.json?preview=1` (about 300 points) or `?player=1` (everything) |
| Upload | `POST /data` with a `gml` parameter |

Rendering what you download is covered in
[sample playback code](../gml/playback-implementations.md), which collects
community implementations across C++, Processing, Javascript, PHP and Python.
