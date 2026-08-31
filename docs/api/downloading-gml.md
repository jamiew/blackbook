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

Latest tag by a specific user:

```
curl http://000000book.com/tempt1/latest.gml
```

Latest from a specific application:

```
curl http://000000book.com/latest.gml?application=eyewriter
```
