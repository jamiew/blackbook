# Drawing GML with Javascript and JSON

The site's own player is [canvasplayer](https://github.com/jamiew/canvasplayer):
plain HTML canvas, ES modules, no dependencies. Every tag page, grid cell and
app card on 000000book is drawn by it. The same files are vendored under
`public/canvasplayer/<version>/` in this repo.

- Demo: <https://jamiew.github.io/canvasplayer>
- Code: <https://github.com/jamiew/canvasplayer>

Any tag is available as JSON at `/data/:id.json`. `?preview=1` cuts it to
about 300 points for thumbnails and `?player=1` returns the full-fidelity
payload the site plays; see [Downloading GML](../api/downloading-gml.md).
