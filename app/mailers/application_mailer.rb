class ApplicationMailer < ActionMailer::Base
  default from: '000000book <no-reply@000book.com>'
  default_url_options[:host] = '000000book.com'
  layout 'mailer'
end
