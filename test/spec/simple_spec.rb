require File.join(File.dirname(__FILE__), *%w[spec_helper])

describe Simple do
  before(:all) do
    Simple.delete_table
  end
  before(:each) do
    simple = Simple.find(1)
    simple.delete if(!simple.nil?)
  end
  
  it "should allow you to store binary data" do  
    con = nil
    lambda{
      con = Simple.create(:my_id => 1, :some_value => "hello", :binary_value => {:hello => :sup})
    }.should_not raise_error
    con.hash_key.should == 1
    con.some_value.should == "hello"
    con = Simple.find(1)
    con.binary_value[:hello].should == :sup
  end

  it "should ingore nils" do
    con = nil
    lambda{
      con = Simple.create(:my_id => 1, :some_value => "sup", :binary_value => nil)
    }.should_not raise_error
    con.hash_key.should == 1
    con.some_value.should == "sup"
    con = Simple.find(1)
    con.binary_value.should be_nil
  end

  it "should allow you to store binary data removing default_proc" do  
    con = nil
    hsh = Hash.new{|h, k|  h[k] = :a}
    hsh[:hello] = :sup
    lambda{
      con = Simple.create(:my_id => 1, :some_value => "hello", :binary_value => hsh)
    }.should_not raise_error
    con.hash_key.should == 1
    con.some_value.should == "hello"
    con = Simple.find(1)
    con.binary_value[:hello].should == :sup
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
