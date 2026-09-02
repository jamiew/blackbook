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
  rescue ActiveStorage::InvariableError
    # The corpus holds zero-byte and truncated images, which Marcel types as
    # application/octet-stream. Without this one bad row 500s a whole index.
    default_attachment_url(record, name, style)
  end

  def default_attachment_url(record, name, style)
    if record.respond_to?(:default_image_url)
      record.default_image_url(style)
    else
      # Users have no default photo of their own; this is the shared blank.
      "/images/defaults/#{name}_#{style}.jpg"
    end
  end

  # Tempt's tags used to be served from fffff.at rather than attached here, and
  # the remote URL took precedence. That host stopped serving them, so every one
  # of his 133 tags rendered as a broken image. The attachment wins now, and the
  # dead host is not consulted at all: a 500 is worse than the placeholder.
  # Tag#remote_image is kept as provenance, and as the key the import joins on.
  def tag_thumbnail_url(tag, style = :medium)
    attachment_url(tag, :image, style)
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
