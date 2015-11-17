require 'rails_helper'


describe GMLObject do
  before(:each) do
    @gml = Factory(:gml_object)
  end

  it "should not create without a Tag" do
    expect { Factory.create(:gml_object, :tag => nil) }.to raise_error
  end

  it 'should not create without any data' do
    expect { Factory.create(:gml_object, :gml => nil) }.to raise_error
  end
end
