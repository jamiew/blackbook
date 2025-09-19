# frozen_string_literal: true

class UserSession < Authlogic::Session::Base
  record_selection_method :find_by_login_or_email
end
