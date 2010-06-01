class Mailer < ActionMailer::Base
  default_url_options[:host] = SiteConfig.host_name

  def password_reset_instructions(user)
    subject       "Password Reset Instructions"
    from          "#{SiteConfig.app_name} <#{SiteConfig.email_from}>"
    recipients    user.email
    sent_on       Time.now
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  end

  def signup_notification(user)
    subject       "Account registration info"
    from          "#{SiteConfig.app_name} <#{SiteConfig.email_from}>"
    recipients    user.email
    bcc           ["info+signups@000000book.com"]
    body          :user => user
  end

  # def comment_notification(comment, user)
  #   subject       "New comment"
  #   from          "#{SiteConfig.app_name} <#{SiteConfig.email_from}>"
  #   recipients    recipient.email
  #   bcc           ["info+signups@000000book.com"]
  #   body          :comment => comment, :user => user
  # end

  # - New tag posted?
  # - Wall posts?
  # - Favorites..?

end
