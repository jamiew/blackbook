# Downloading GML

- Every tag page has a "Download GML" button.
- Or append `.gml` to any data page URL, e.g. `http://000000book.com/data/154.gml`
- Other formats work too: `.json` includes the full GML as JSON, and `.xml` gives
  metadata only. For more on JSON (GSON) see
  [Drawing GML with Javascript and JSON](../gml/javascript-and-json.md).

## Other handy API access points

Latest tag uploaded site-wide:

```
curl http://000000book.com/latest.gml
```

A random tag:

```
curl http://000000book.com/random.gml
```

To filter, use the index rather than `/latest`. `/data` accepts `user_id`,
`app`, `location` and `keywords`:

```
curl "http://000000book.com/data.json?app=eyewriter"
curl "http://000000book.com/data.json?user_id=tempt1"
```

`/latest` and `/random` take no filters: they always return the newest and a
random tag site-wide.
