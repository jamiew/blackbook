# Uploading GML to 000000book.com

Sending your application's GML data to blackbook is simple. Authenticating or
registering your app is optional.

Send an HTTP POST to `http://000000book.com/data` with a payload containing:

- **gml** (text, required) — the complete GML data. Validated for required GML
  fields, e.g. at least one x/y point.
- **application** (string) — the name of your application. Not enforced, but
  send it: it is how uploads are attributed and how `/data?app=` filters.

## Sample

On macOS or Linux you can test uploading with `curl`:

```
curl -A curlwriter \
  -d 'application=curlwriter&gml=<gml><stroke><pt><x>1</x><y>1</y><t>1</t></pt></stroke></gml>' \
  http://000000book.com/data
```

- `-A` sets a user-agent
- `-d` is the POST data, which needs only `application` and `gml`

The recorder at [/upload](http://000000book.com/upload) writes a valid file in
the browser if you want one to test with.

## Optional fields

These can be specified either in the GML itself **or** via HTTP POST, in which
case 000000book writes them into the GML for you.

- **keywords** (string) — comma-separated list of keywords. These are tags in
  the metadata sense, not graffiti tags.
- **location** (string) — a name like "NYC", lat/long coordinates, or a URL.
- **uniqueKey** (string) — a unique device id for device pairing, e.g. an iPhone
  UUID or a computer's MAC address. Note: this field must currently be in the
  GML; it is not accepted via POST.
- **username** (string) — a 000000book user's login.
- **author** (string) — the person who was actually writing.

The `uniqueKey` payload uniquely identifies the uploading device. Users can
later pair their 000000book account with a given uniqueKey.

Treat it as a credential, not metadata: anyone who has it can have their own
uploads attributed to that device's owner. We never give it back out. It is
stripped from every GML we serve and never appears in `.json` or `.xml`, so a
tag you download will not contain the `<uniqueKey>` you uploaded. Send a value
that is hard to guess, and do not reuse one across users.
