# Uploading GML to 000000book.com

Send an HTTPS POST to `https://000000book.com/data` with a `gml` parameter
containing the complete XML. No account or API key is required. Uploads are
limited to 30 per hour per IP; a `429` response includes `Retry-After`.

## Sample

This command creates a public tag. Use a local server instead when testing.
`--data-urlencode` preserves XML containing characters such as `&` or `+`.

```bash
curl --data-urlencode 'application=curlwriter' \
  --data-urlencode 'gml=<gml spec="1.0"><tag><header><client><name>curlwriter</name></client></header><drawing><stroke><pt><x>0.1</x><y>0.1</y><time>0</time></pt><pt><x>0.8</x><y>0.8</y><time>1</time></pt></stroke></drawing></tag></gml>' \
  https://000000book.com/data
```

To upload a file, replace the inline XML argument with
`--data-urlencode 'gml@drawing.gml'`. Success returns `200` with the new tag ID
as plain text. Use `/data/<id>` to view it. Requests with no GML or a failed
model validation return `422`; a successful upload is not proof of valid GML.

The recorder at [/upload](https://000000book.com/upload) produces the expected
file structure. Drawing data belongs under `<gml><tag><drawing>`, with `<stroke>`
elements containing `<pt>` elements. Points use `<x>`, `<y>` and `<time>` (not
`<t>`). The [validator](https://000000book.com/validator) checks for strokes,
points and coordinates and reports missing capture metadata. These diagnostic
checks do **not** run as upload validations.

## Metadata

The API accepts these additional POST fields:

- **application**: application name, used for attribution and `?app=` filtering.
- **location**: free-text location.
- **uniquekey**: optional device-pairing credential; lowercase in POST.
- **image**: an uploaded image file, sent as multipart form data.

These fields are stored with the tag; they are not inserted into its GML.
The server also reads `<name>`, `<username>`, `<keywords>`, `<location>` and
`<uniqueKey>` from `<gml><tag><header><client>`. Nonempty header values populate
the corresponding metadata; header location and uniqueKey override POST values.
`keywords`, `username` and `author` are not accepted as separate POST fields.
A GML username is descriptive metadata, not account authentication.

## Device pairing

A user can set the matching device key in their account settings. Uploads with
that key are assigned to the paired account.

Treat the key as a credential: anyone who has it can attribute uploads to the
paired account. Generate a hard-to-guess value rather than a MAC address or other
public identifier, and do not share it across users. Public GML, JSON and XML
responses omit the key; downloaded GML therefore differs from the uploaded file.
