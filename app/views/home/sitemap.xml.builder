xml.instruct!
xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
  [root_url, tags_url, visualizations_url, upload_url, about_url, docs_url].each do |url|
    xml.url { xml.loc url }
  end
  @docs.each do |doc|
    xml.url { xml.loc request.base_url + doc.url_path }
  end
  @apps.each do |app|
    xml.url do
      xml.loc visualization_url(app)
      xml.lastmod app.updated_at.to_date.iso8601 if app.updated_at
    end
  end
  @tags.each do |tag|
    xml.url do
      xml.loc tag_url(tag)
      xml.lastmod tag.updated_at.to_date.iso8601 if tag.updated_at
    end
  end
end
