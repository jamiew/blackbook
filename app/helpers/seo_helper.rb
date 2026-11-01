# What a page says about itself to search engines and agents, as JSON-LD.
# The layout adds the site and its publisher; these describe the page.
module SeoHelper
  PUBLISHER = { '@id' => 'https://fffff.at/#org' }.freeze

  def tag_structured_data(tag)
    still = content_for(:og_image).presence
    {
      '@context' => 'https://schema.org', '@type' => 'CreativeWork',
      'name' => "Tag ##{tag.id}", 'url' => tag_url(tag), 'dateCreated' => tag.created_at.iso8601,
      'creator' => { '@type' => 'Person', 'name' => tag_author(tag) },
      'isPartOf' => { '@type' => 'Dataset', 'name' => '000000book', 'url' => tags_url },
      'encodingFormat' => 'application/xml',
      'keywords' => tag.gml_keywords.presence, 'contentLocation' => tag.location.presence,
      'associatedMedia' => { '@type' => 'DataDownload', 'name' => 'Graffiti Markup Language file',
                             'contentUrl' => tag_url(tag, format: :gml), 'encodingFormat' => 'application/xml' },
      'image' => still && URI.join(request.base_url, still).to_s
    }.compact
  end

  def app_structured_data(app)
    {
      '@context' => 'https://schema.org', '@type' => 'SoftwareApplication',
      'name' => app.name, 'url' => visualization_url(app), 'applicationCategory' => 'DesignApplication',
      'description' => app.description.presence, 'softwareVersion' => app.version.presence,
      'author' => app.authors.presence && { '@type' => 'Person', 'name' => app.authors },
      'sameAs' => app.website.presence, 'codeRepository' => app.source_url.presence,
      'image' => app.image.attached? ? URI.join(request.base_url, attachment_url(app, :image, :large)).to_s : nil
    }.compact
  end

  def dataset_structured_data(total)
    {
      '@context' => 'https://schema.org', '@type' => 'Dataset',
      'name' => '000000book: the Graffiti Markup Language archive',
      'description' => "Motion-captured graffiti tags as GML files. Each is a writer's hand as timed x and y " \
                       'coordinates, uploaded by capture apps since 2009. Public, no key needed.',
      'url' => tags_url, 'isAccessibleForFree' => true, 'temporalCoverage' => "2009/#{Date.current.year}",
      'creator' => PUBLISHER, 'size' => "#{total} tags",
      'distribution' => [
        { '@type' => 'DataDownload', 'encodingFormat' => 'application/json', 'contentUrl' => tags_url(format: :json) },
        { '@type' => 'DataDownload', 'encodingFormat' => 'application/rss+xml',
          'contentUrl' => tags_url(format: :rss) },
        { '@type' => 'DataDownload', 'encodingFormat' => 'application/yaml', 'name' => 'OpenAPI description',
          'contentUrl' => "#{request.base_url}/openapi.yaml" }
      ]
    }
  end

  def doc_structured_data(doc)
    {
      '@context' => 'https://schema.org', '@type' => 'TechArticle', 'headline' => doc.title,
      'url' => request.base_url + doc.url_path, 'inLanguage' => 'en',
      'isPartOf' => { '@id' => "#{request.base_url}/#website" },
      'encoding' => { '@type' => 'MediaObject', 'encodingFormat' => 'text/markdown',
                      'contentUrl' => "#{request.base_url}#{doc.url_path}.md" }
    }
  end
end
