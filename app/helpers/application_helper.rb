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
      if flash[msg.to_sym].present?
        messages << content_tag(:div, html_escape(flash[msg.to_sym]), :id => "flash-#{msg}").html_safe
      end
    end
    @flash_messages ||= messages
  end

  # TODO FIXME -- I think this did generic ActiveRecord .error_messages mapping
  # so like controller.send(object_name).map(&:error_messages)? something like that
  def error_messages_for(object_name)
    "TODO show errors for #{object_name}"
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
