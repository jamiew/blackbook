module CommentsHelper
  # make a sexy name for the object we're referencing
  # TODO -- this could be merged with activity-style stuff
  #       we need sexy names for almost everything!
  def commentable_name(obj)
    return obj.name if obj.respond_to?(:name) && obj.name.present?
    return obj.title if obj.respond_to?(:title) && obj.title.present?
    return obj.login if obj.respond_to?(:login) && obj.login.present? # User-specificish

    "#{obj.class} ##{obj.id}"
  end
end
