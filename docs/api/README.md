# The 000000book API

Use HTTPS to upload and download tags. No API key or SDK is required.
Append `.gml` for the drawing, `.json` for metadata and GML, or `.xml` for
metadata only.

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
| For drawing | `/data/154.json?preview=1` (sampled points) or `?player=1` (playback data) |
| Upload | `POST /data` with a `gml` parameter |
| These docs as markdown | `/docs/README.md`, `/docs/api.md`, or append `.md` to a page URL |

Rendering what you download is covered in
[sample playback code](../gml/playback-implementations.md), which collects
community implementations across C++, Processing, Javascript, PHP and Python.
