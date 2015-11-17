require 'rails_helper'


RSpec.describe GmlObject, type: :model do

  before(:each) do
    # @gml = FactoryGirl.build(:gml_object)
  end

  it "should not create without a Tag" do
    lambda { FactoryGirl.create(:gml_object, :tag => nil) }.should raise_error
  end

  it 'should not create without any data' do
    lambda { FactoryGirl.create(:gml_object, :data => nil) }.should_not raise_error
  end
end
