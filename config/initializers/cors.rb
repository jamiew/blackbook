# Cross-origin access to the public API.
#
# Middleware rather than headers set in an action, for three reasons: it covers
# .gml and .xml as well as .json, it answers the OPTIONS preflight without
# needing a route for it, and at position 0 it runs before the beta basic-auth
# gate in ApplicationController. Before this existed the only way to read our
# data from a browser was JSONP, which is why the site's own canvas player still
# injects a <script> tag.
#
# POST is allowed deliberately. CORS is not a write control: an HTML form on any
# origin can already POST /data today, and refusing it here would only stop a
# legitimate browser uploader from reading back the tag id it gets in return.
# The rate limits in TagsController are the actual control.
#
# No credentials, because the API is anonymous. `origins '*'` with credentials
# is both forbidden by the spec and a way to leak a logged-in session.
#
# Patterns: rack-cors turns `/*` into `\/?(.*?)`, so `/data/*` already covers
# `/data`, `/data.json`, `/data/154.gml` and `/data/154/validate`.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    %w[
      /data/*
      /latest*
      /random*
      /validate*
      /apps/*
      /users/*
    ].each do |path|
      resource path,
               headers: :any,
               methods: %i[get head options post],
               credentials: false,
               max_age: 86_400
    end
  end
end
