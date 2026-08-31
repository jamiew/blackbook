module ApplicationHelper
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

  # Counts for the instrument bar under the masthead. Cached because it runs on
  # every page and Tag.count is a full scan of ~77k rows.
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
