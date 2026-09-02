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

  def tag_thumbnail_url(tag, style = :medium)
    tag.remote_thumbnail_url || attachment_url(tag, :image, style)
  end

  # Writers and apps store a website as typed, so it may lack a scheme or be
  # blank. Nil when blank, so a view can `= website_link(x)` and print nothing.
  def website_link(url)
    return if url.blank?

    scheme = %r{\Ahttps?://}i
    href = url.match?(scheme) ? url : "http://#{url}"
    link_to url.sub(scheme, '').chomp('/'), href, rel: 'nofollow noopener', target: '_blank'
  end

  def html_attrs(lang = 'en-US')
    { lang: lang }
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

  def nav_link(label, path, active: [])
    current = active.include?(controller_name)
    link_to label, path, 'aria-current' => (current ? 'page' : nil)
  end

  # Archive counts for the home page. Cached because Tag.count is a full scan
  # of ~77k rows.
  def archive_stats
    @archive_stats ||= Rails.cache.fetch('archive_stats', expires_in: 5.minutes) do
      today = Time.current.in_time_zone('Pacific Time (US & Canada)').to_date
      today_scope = Tag.where('created_at >= ?', today)
      { total: Tag.count, today: today_scope.count, writers: today_scope.distinct.count(:gml_uniquekey) }
    end
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
