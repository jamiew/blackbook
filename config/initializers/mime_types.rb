# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

# Graffiti Markup Language (.gml)
# Mime::Type.register "application/xml", :gml
Mime::Type.register_alias "application/xml", :gml

# Treat XHRs as a separate format from straight-up HTML
# TODO FIXME
Mime::Type.register_alias "text/html", :xhr
