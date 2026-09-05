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

  # The vendored canvasplayer. It is served from public/ because Propshaft would
  # fingerprint the files and break the modules' relative imports. See SOURCE in
  # that directory for the commit and how to update; bump the version here.
  def canvasplayer_path(file = nil)
    ['/canvasplayer/6.0.1', file].compact.join('/')
  end

  # A link that turns one filter on, or off when it already is, keeping the
  # other filters and everything else in the query. `keys` are the page's
  # filters; an empty `on` is the All chip, which clears them.
  def filter_chip(label, on = {}, keys:)
    on = on.stringify_keys
    active = on.empty? ? keys.none? { |k| params[k].present? } : on.all? { |k, v| params[k].to_s == v.to_s }
    query = request.query_parameters.except('page')
    query = if on.empty?
              query.except(*keys)
            elsif active
              query.except(*on.keys)
            else
              query.merge(on)
            end
    link_to label, url_for(query.merge(only_path: true)), class: 'chip', 'aria-current' => (active ? 'true' : nil)
  end

  # A JSON-LD block for the head. Rails' encoder escapes < and >, so a
  # `</script>` inside a description cannot break out of the tag.
  def json_ld(data)
    content_tag(:script, data.to_json.html_safe, type: 'application/ld+json')
  end

  # Who a tag is by, for titles and descriptions: the account, the device's
  # codename, or nobody.
  def tag_author(tag)
    tag.user&.login || tag.secret_username || 'an anonymous writer'
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

  # `active` names the controllers a section covers; with none given the link
  # is current only on its own page.
  def nav_link(label, path, active: [], css: nil)
    current = active.include?(controller_name) || (active.empty? && current_page?(path))
    link_to label, path, class: css, 'aria-current' => (current ? 'page' : nil)
  end

  # How many tags the archive holds, for the front page. Cached because
  # Tag.count is a full scan of ~77k rows.
  def archive_total
    Rails.cache.fetch('archive_total', expires_in: 5.minutes) { Tag.count }
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
