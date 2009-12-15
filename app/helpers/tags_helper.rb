module TagsHelper
  
  # Tag flash visualizer -- allow people to customize
  # If no tag specified try to do "slideshow" mode (??)
  def tag_player(tag = nil, args = {})
    STDERR.puts tag.inspect
    opts = { :width => '100%', :height => '100%', :src => 'http://toddvanderlin.com/content/000000book/BlackBook.swf', :bgcolor => '#000000' }.merge(args)
    %{    
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" width="#{opts[:width]}" height="#{opts[:height]}" id="BlackBook" align="middle">
        <!-- typical shit -->
        <param name="allowScriptAccess" value="sameDomain" />
        <param name="allowFullScreen" value="true" />
        <param name="quality" value="high" />
        <param name="scale" value="noscale" />
        <param name="wmode" value="gpu" />
        <param name="loop" value="true" />
        <param name="movie" value="#{opts[:src]}" />
        <param name="bgcolor" value="#{opts[:bgcolor]}" />
        
        <!-- blackbook data -->
        <param name="blackbook_gml_url" value="#{tag_url(tag, :format => 'gml')}" />
        <param name="blackbook_embed" value="&lt;embed&gt;TODOWHATUP&lt;/embed&gt;" />
        <param name="blackbook_id" value="#{tag.id}" />
        <param name="blackbook_application" value="#{tag.application}" />
        <param name="blackbook_user" value="#{tag.user.login rescue ''}" />
        <param name="blackbook_user_id" value="#{tag.user_id}" />
        <param name="blackbook_location" value="#{tag.location}" />
        <param name="blackbook_image_large" value="#{tag.image.url(:large)}" />
        <param name="blackbook_image_medium" value="#{tag.image.url(:medium)}" />
        <param name="blackbook_image_small" value="#{tag.image.url(:small)}" />
        
        <!-- embed itself -->
        <embed src="#{opts[:src]}" quality="high" scale="noscale" wmode="gpu" bgcolor="#{opts[:bgcolor]}" width="#{opts[:width]}" height="#{opts[:height]}" name="BlackBook" align="middle" allowScriptAccess="sameDomain" allowFullScreen="false" type="application/x-shockwave-flash" pluginspage="http://www.adobe.com/go/getflashplayer" />
      </object>
    }
  end
  alias :tag_vis :tag_player
  
end
