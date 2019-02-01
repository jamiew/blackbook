class Mailer < ActionMailer::Base
  default_url_options[:host] = '000000book.com'

  def password_reset_instructions(user)
    subject       "Password Reset Instructions"
    from          "000000book <noreply@000000book.com>"
    recipients    user.email
    sent_on       Time.now
    body          edit_password_reset_url: edit_password_reset_url(user.perishable_token)
  end

  def signup_notification(user)
    subject       "Account registration info"
    from          "000000book <noreply@000000book.com>"
    recipients    user.email
    bcc           ["info+signups@000000book.com"]
    body          user: user
  end

  # def comment_notification(comment, user)
  #   subject       "New comment"
  #   from          "000000book <noreply@000000book.com>"
  #   recipients    recipient.email
  #   bcc           ["info+signups@000000book.com"]
  #   body          comment: comment, user: user
  # end

  # TODO New tag posted
  # TODO Wall posts
  # TODO Favorited one of your tags

end
