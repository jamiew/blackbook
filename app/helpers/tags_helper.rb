module TagsHelper

  # default a title for a piece of data...
  def tag_title(tag)
    tag.title.blank? ? "##{tag.id}" : tag.title
  end

  def tag_user_link(tag)
    if !tag.user.nil?
      link_to tag.user.login, user_path(tag.user), :class => 'username_link'
    elsif !tag.secret_username.blank?
      secret_username_link(tag.secret_username)
    else
      'NULL'
    end
  end

  # For anonymous users
  def secret_username_link(secret_username)
    link_to secret_username, tags_path(:user => secret_username), :class => 'username_link anon'
  end

  def application_link(app_name, opts = {})
    return "[manual]" if app_name.blank?
    # Strip out the long-ass GA name...
    # shortname = (opts[:short] == true ? app_name.gsub('Graffiti Analysis ','GrafAnalysis') : app_name)
    shortname = app_name
    link_to shortname, tags_path(:app => app_name), :class => 'application_link anon'
  end

  def location_link(location, opts = {})
    return "NULL" if location.blank?
    link_to(location, tags_path(:location => location), :class => 'location_link')
  end


  # Tag flash visualizer -- allow people to customize
  # If no tag specified try to do "slideshow" mode (??)
  def tag_player(tag = nil, args = {})

    return '<br /><p><strong>[disabled in dev mode]</strong></p><br />' if dev? && !params[:flash]

    # No longer specifying a specific height, just width
    opts = { :width => '100%', :src => 'http://toddvanderlin.com/content/000000book/BlackBook.swf', :bgcolor => '#000000' }.merge(args)

    # image_urls = tag.image.styles.keys.map { |s| ["image_#{s}", "http://#{request.host}:#{request.port}"+tag.image.url(s)] }.to_hash
    image_urls = {:image_large => tag.image.url(:large)}
    flashvars = { :gml_url => tag_url(tag, :format => 'gml', :iphone_rotate => (tag.from_iphone? ? '1' : nil)), :embed => "&lt;embed&gt;TODOWHATUP&lt;/embed&gt;",
        :user => (tag.user.login rescue nil),
        :created_at => tag.created_at.to_s, :created_date => tag.created_at.strftime("%D")
      }.merge(image_urls)

    public_attributes = ['id','application','location','user_id']
    flashvars.merge!( tag.attributes.select { |k,v| public_attributes.include?(k) } )

    querified_flashvars = flashvars.map { |k,v| "#{k}=#{v.blank? ? '' : CGI.escape(v.to_s)}" }.join('&')
    embed = %{<embed src="#{opts[:src]}?#{querified_flashvars}" quality="high" scale="noscale" wmode="gpu" loop="true" bgcolor="#{opts[:bgcolor]}" width="#{opts[:width]}" name="BlackBook" align="middle" allowScriptAccess="always" allowFullScreen="true" type="application/x-shockwave-flash" pluginspage="http://www.adobe.com/go/getflashplayer" />}

    %{
      <object width="#{opts[:width]}">

        <!-- typical flash noise; note allowScriptAccess (for js), allowFullScreen=true, loop=true, bgcolor=BLACK -->
        <param name="allowScriptAccess" value="always" />
        <param name="allowFullScreen" value="true" />
        <param name="quality" value="high" />
        <param name="scale" value="noscale" />
        <param name="wmode" value="gpu" />
        <param name="loop" value="true" />
        <param name="movie" value="#{opts[:src]}" />
        <param name="bgcolor" value="#{opts[:bgcolor]}" />

        <!-- blackbook data, also passed as flashvars -->
        #{flashvars.map { |key, value| "<param name=\"#{key}\" value=\"#{value}\" />\n        " } }

        #{embed}

      </object>
    }
  end
  alias :tag_vis :tag_player

end
