module ActiveRecord
  class Base
    class << self
      def boolean_field(*args)
        args.each {|prop|
          class_eval(<<-EODEF
            def #{prop}?
              #{prop} === true || #{prop} === 1
            end
          EODEF
          )
        }
      end

      def nil_if_blank(*args)
        args.each {|prop|
          class_eval(<<-EODEF
            def #{prop}
              val = super
              nil if val.blank?
            end
          EODEF
          )
        }
      end
    end
  end
end

module ActionController
  begin
    class AbstractRequest
      def referrer
        self.env['HTTP_REFERER']
      end
    end
  rescue
    class AbstractRequest
      def referrer
        self.env['HTTP_REFERER']
      end
    end
  end

  class Base
    class << self
      def simple_action(*actions)
        actions.each {|action| class_eval("def #{action}; end")}
      end

      def forbidden_action(*actions)
        actions.each {|action|
          class_eval(
            <<-EOEVAL
            def #{action}
              respond_to do |format|
                format.html { render :status => :forbidden, :template => '/shared/forbidden' }
                format.xml  { render :nothing => true, :status => :forbidden }
                format.json { render :nothing => true, :status => :forbidden }
                format.xhr  { render :nothing => true, :status => :forbidden }
              end
            end
            EOEVAL
          )
        }
      end
    end
  end
end

module ApplicationHelper
  module_eval do
    def stylesheet_controller_tag
      stylesheet_link_tag(controller.controller_name) if
        public_file_exists?(stylesheet_path(controller.controller_name))
    end

    def javascript_controller_tag
      javascript_include_tag(controller.controller_name) if
        public_file_exists?(javascript_path(controller.controller_name))
    end

    def javascript_action_tag
      name = "#{controller.controller_name}_#{controller.action_name}"
      javascript_include_tag(name) if
        public_file_exists?(javascript_path(name))
    end

    def public_file_exists?(file)
      File.exist?(public_file_path(file))
    end

    def public_file_path(file)
      file ||= ''
      File.expand_path(File.join(RAILS_ROOT, 'public', file.gsub(/\?.*$/, '')))
    end

    def distance_of_time_for(obj, method)
      begin
        date_time = obj.send(method)
        date_time = Time.parse(date_time) if date_time.is_a?(String)
        from_ago = date_time < Time.new ? 'ago' : 'from now'
        "<span title=\"#{date_time.localtime}\">#{distance_of_time_in_words_to_now(date_time.localtime)} #{from_ago}</span>"
      rescue
        "<span style=\"display:none\">object does not respond to #{method}</span>"
      end
    end

    def back_link(text='Back', *args)
      link_to text, (request.referrer || 'javascript:history.go(-1)'), *args
    end

    def current_controller?(*options)
      begin
        options = options[1] if options.is_a?(Array)
        return false unless options.useful? || options.is_a?(Hash)
        opts = options.dup
        opts[:action] = :index
        url_for({:action => :index}) == url_for(opts)
      rescue Exception; end
    end
  end
end



# jdubs display/provdes + to_html merb emulation mode code

# a simple ActiveRecord->HTML table of attributes default (why isn't this builtin?) 
# in the case of arrays, just do many tables
# TODO: move to a plugin or somesuch?
module ToHTML

  def to_html(opts = {})
    
    # TODO FIXME merge in opts[:exclude]
    @private_attributes ||= [:id, :video_id, :user_id, :cached_tag_list, :points, :identified, :identified_at, :created_at, :service_id]
    
    object = self
    str = ''
    [*object].each { |obj|
      
      str << "<table>\n"
      data = case obj
      when ActiveRecord::Base
        obj.attributes.reject { |k,v| @private_attributes.include?(k.to_sym) }
      when Hash
        obj
      else
        raise "Don't know how to render to_html for an `#{object.class}` => #{object.inspect}"
      end
      
      data.each { |k,v|
        str << "\t<tr><td>#{k}</td><td>#{v}</td></tr>\n"
      }
      str << "</table>\n"
    }
    return str
  end
end


# mix to_html into ActiveRecord + arrays of ARs, as well as Hash
ActiveRecord::Base.send(:include, ToHTML)
Hash.send(:include, ToHTML)
Array.send(:include, ToHTML)





