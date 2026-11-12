# Drawing GML with Javascript and JSON

The site's own player is [canvasplayer](https://github.com/jamiew/canvasplayer):
plain HTML canvas, ES modules, no dependencies. Every tag page, grid cell and
app card on 000000book is drawn by it. The same files are vendored under
`public/canvasplayer/<version>/` in this repo.

- Demo: <https://jamiew.github.io/canvasplayer>
- Code: <https://github.com/jamiew/canvasplayer>

Any tag is available as JSON at `/data/:id.json`. `?preview=1` samples points
for thumbnails; `?player=1` returns the site's normalized playback data.
Use `.gml` or unqualified `.json` when you need the original drawing fields.
See [Downloading GML](../api/downloading-gml.md).
