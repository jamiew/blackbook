module TagsHelper
  # default a title for a piece of data...
  def tag_title(tag)
    tag.title.presence || "##{tag.id}"
  end

  def tag_user_link(tag)
    if !tag.user.nil?
      link_to tag.user.login, user_path(tag.user), class: 'username_link'
    elsif tag.secret_username.present?
      secret_username_link(tag.secret_username)
    else
      'NULL'
    end
  end

  def secret_username_link(secret_username)
    link_to secret_username, tags_path(user: secret_username), class: 'username_link anon'
  end

  def application_link(app_name, _opts = {})
    return "[upload]" if app_name.blank?

    # Strip out the long-ass GA name...
    # shortname = (opts[:short] == true ? app_name.gsub('Graffiti Analysis ','GrafAnalysis') : app_name)
    shortname = app_name
    link_to shortname, tags_path(app: app_name), class: 'application_link anon'
  end

  def location_link(location, _opts = {})
    return "NULL" if location.blank?

    link_to(location, tags_path(location: location), class: 'location_link')
  end

  # Playback now lives in tags/_player.html.haml and player.js. The Flash
  # embed that used to be here pointed at a .swf and stopped working when the
  # plugin was withdrawn in 2020.
end
