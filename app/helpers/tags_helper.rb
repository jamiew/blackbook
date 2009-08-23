module TagsHelper
  
  # Tag flash visualizer -- allow people to customize
  # If no tag specified try to do "slideshow" mode (??)
  def tag_player(tag = nil, args = {})
    opts = { :width => '100%', :height => '100%', :src => 'BlackBook.swf', :bgcolor => '#000000' }.merge(args)
    %{    
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" width="#{opts[:width]}" height="#{opts[:height]}" id="BlackBook" align="middle">
        <param name="allowScriptAccess" value="sameDomain" />
        <param name="allowFullScreen" value="false" />
        <param name="movie" value="/#{opts[:src]}" />
        <param name="quality" value="high" />
        <param name="scale" value="noscale" />
        <param name="wmode" value="gpu" />
        <param name="bgcolor" value="#{opts[:bgcolor]}" />	
        <embed src="/#{opts[:src]}" quality="high" scale="noscale" wmode="gpu" bgcolor="#{opts[:bgcolor]}" width="#{opts[:width]}" height="#{opts[:height]}" name="BlackBook" align="middle" allowScriptAccess="sameDomain" allowFullScreen="false" type="application/x-shockwave-flash" pluginspage="http://www.adobe.com/go/getflashplayer" />
      </object>
    }
  end
  alias :tag_vis :tag_player
  
end
