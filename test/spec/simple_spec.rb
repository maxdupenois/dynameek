require File.join(File.dirname(__FILE__), *%w[spec_helper])

describe Simple do
  before(:all) do
    Simple.delete_table
  end
  before(:each) do
    simple = Simple.find(1)
    simple.delete if(!simple.nil?)
  end
  it "should allow you to create a new simple" do
    con = nil
    lambda{
      con = Simple.create(:my_id => 1, :some_value => "hello")
    }.should_not raise_error
    con.hash_key.should == 1
    con.some_value.should == "hello"
  end
  it "should allow you to find a created simple" do
     Simple.create(:my_id => 1, :some_value => "hello")
     con = Simple.find(1)
     con.hash_key.should == 1
     con.some_value.should == "hello"
   end
  
end