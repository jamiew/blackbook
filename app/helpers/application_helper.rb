module ApplicationHelper
  # Paperclip returned a URL for record.image(:style) and quietly substituted a
  # default when nothing was attached. Active Storage raises instead, so the
  # fallback lives here rather than in every view.
  #
  # `style` is a named variant declared on the model, so the geometry stays
  # with the attachment rather than being repeated at each call site.
  def attachment_url(record, name, style)
    attachment = record.public_send(name)
    return default_attachment_url(record, name, style) unless attachment.attached?

    url_for(attachment.variant(style))
  end

  def default_attachment_url(record, name, style)
    if record.respond_to?(:default_image_url)
      record.default_image_url(style)
    else
      # Users have no default photo of their own; this is the shared blank.
      "/images/defaults/#{name}_#{style}.jpg"
    end
  end

  def tag_thumbnail_url(tag, style = :medium)
    tag.remote_thumbnail_url || attachment_url(tag, :image, style)
  end

  def attachment_attached?(record, name)
    record.public_send(name).attached?
  end

  def html_attrs(lang = 'en-US')
    { xmlns: "http://www.w3.org/1999/xhtml", 'xml:lang' => lang, lang: lang }
  end

  def http_equiv_attrs
    { 'http-equiv' => 'Content-Type', content: 'text/html;charset=UTF-8' }
  end

  def flash_messages
    messages = []
    %w[notice warning error].each do |msg|
      if flash[msg.to_sym].present?
        messages << content_tag(:div, html_escape(flash[msg.to_sym]), id: "flash-#{msg}").html_safe
      end
    end
    @flash_messages ||= messages
  end

  def pagination(collection = nil)
    collection.nil? ? will_paginate : will_paginate(collection)
  end

  def timeago(timestamp)
    time_ago_in_words(timestamp)
  end

  def redstar
    '<span style="color: #f55">*</span>'.html_safe
  end
end
