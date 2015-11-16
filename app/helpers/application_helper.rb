module ApplicationHelper

  # dirty ugly hack to get rcov to see this
  def html_attrs(lang = 'en-US')
    { :xmlns => "http://www.w3.org/1999/xhtml", 'xml:lang' => lang, :lang => lang }
  end

  def http_equiv_attrs
    { 'http-equiv' => 'Content-Type', :content => 'text/html;charset=UTF-8' }
  end


  # Outputs the corresponding flash message if any are set
  def flash_messages
    messages = []
    %w(notice warning error).each do |msg|
      messages << content_tag(:div, html_escape(flash[msg.to_sym]), :id => "flash-#{msg}") unless flash[msg.to_sym].blank?
    end
    return messages
  end


  # Javascript includes, used across multiple layouts
  # 'Remote' files are only remote in prod, since we might be offline in dev
  def remote_javascript_includes
    if 'production' == RAILS_ENV
      javascript_include_tag(
        'http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js',
        'http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.1/jquery-ui.min.js'
      )
    else
      javascript_include_tag(
        'jquery.js',
        'jquery-ui.js'
      )
    end
  end

  # Local files are the same in both prod & dev
  def local_javascript_includes
    javascript_include_tag(
      # 'jquery.rater.js',
      'jrails',
      'application'
    )
  end

  # Pagination helper; collection optional as will_paginate will guess based on controller name
  def pagination(collection = nil)
    collection.nil? ? will_paginate : will_paginate(collection)
  end

  # Time wrappers; TODO add jquery.timeago and stop using time_ago_in_words...
  def timeago(timestamp)
    time_ago_in_words(timestamp)
  end

  # DOCME
  def delete_img(obj, path)
    link_to_remote(image_tag('delete.png',
        :title => "Delete this #{obj.class}",
        :class => 'action'
      ), {
        :url => path,
        :method => :delete,
        :confirm => "This happens immediately.\nAre you sure you want to delete it?"
      }
    ) unless obj.id.blank?
  end

  # DOCME
  def edit_img(obj, path)
    link_to(image_tag('pencil.png',
        :title => "Edit this #{obj.class}",
        :class => 'action'
      ),
      path
    ) unless obj.id.blank?
  end

  # ...
  def drag_img
    image_tag 'arrow_up_down.png', :class => 'action drag', :title => 'Drag to reorder'
  end

  # ...
  def sortable(parent, handle='', axis='y', containment='')
    <<-EOC
      $('#{parent} ul').sortable({
        axis: '#{axis}',
        containment: '#{containment}',
        handle: '#{handle}',
        // stop: function() { PNB.updateSortables('#{parent}') }
      })
    EOC
  end


  # Some common elements
  def redstar
    '<span style="color: #f55">*</span>'
  end



end
