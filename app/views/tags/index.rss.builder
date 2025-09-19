# frozen_string_literal: true

# index.rss.builder
xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title page_title
    xml.description((@search_context.blank? ? 'Most recently uploaded tags' : "Tags matching: #{@search_context[:key]}: #{@search_context[:value]}"))
    xml.link tags_url(format: :rss)

    @tags.each do |tag|
      xml.item do
        xml.link tag_url(tag)
        xml.guid "#{tag.class}-#{tag.id}"
        xml.title tag_title(tag)
        xml.description "Uploader: #{tag_user_link(tag)}<br/>\n
          Application: #{application_link(tag.sexy_app_name)}<br/>\n
          Image:<br/>\n
          #{image_tag(tag.thumbnail_image)}\n"
        xml.pubDate tag.created_at.to_fs(:rfc822)
      end
    end
  end
end
