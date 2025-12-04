module ApplicationHelper

  def html_attrs(lang = 'en-US')
    { xmlns: "http://www.w3.org/1999/xhtml", 'xml:lang' => lang, lang: lang }
  end

  def http_equiv_attrs
    { 'http-equiv' => 'Content-Type', content: 'text/html;charset=UTF-8' }
  end

  def flash_messages
    messages = []
    %w(notice warning error).each do |msg|
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
