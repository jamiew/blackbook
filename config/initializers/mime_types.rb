# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

# Treat XHR's as a separate format from straight-up HTML
Mime::Type.register_alias "text/html", :xhr

# GML
Mime::Type.register "application/xml", :gml
# Mime::Type.register_alias "application/xml", :gml