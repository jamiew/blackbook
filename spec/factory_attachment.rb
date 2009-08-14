# code by Josh Nichols from
# http://gist.github.com/162881
require 'action_controller/test_process'
Factory.class_eval do
  def attachment(name, path, content_type = nil)
    path_with_rails_root = "#{RAILS_ROOT}/#{path}"
    uploaded_file = if content_type
                      ActionController::TestUploadedFile.new(path_with_rails_root, content_type)
                    else
                      ActionController::TestUploadedFile.new(path_with_rails_root)
                    end
 
    add_attribute name, uploaded_file
  end
end