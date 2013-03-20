require File.join(File.dirname(__FILE__), *%w[spec_helper])

describe Conversion do
  before(:all) do
    Conversion.delete_table
  end
  before(:each) do
    Conversion.query([1, "google"]).delete
  end
  
  it "should allow you to create a new conversion" do
    con = nil
    lambda{
      con = Conversion.create(:client_id => 1, :channel_id => "google", :goal_name=> "new conversion", :time => DateTime.now)
    }.should_not raise_error
    con.hash_key.should == "1|google" 
  end
  
  
  it "should allow you to find a conversion" do
    now = DateTime.now
    Conversion.create(:client_id => 1, :channel_id => "google", :goal_name=> "find conversion", :time => now)
    con = Conversion.find([1, "google"], now)
    con.should_not be_nil
    con.hash_key.should == "1|google" 
  end
  
  
  it "should allow you to delete a range" do 
    now = DateTime.now
    Conversion.create(:client_id => 1, :channel_id => "google", :goal_name=> "delete conversion", :time => now)
    Conversion.query([1, "google"]).all.size.should == 1
    Conversion.query([1, "google"]).delete
    Conversion.query([1, "google"]).all.size.should == 0
  end
  
  it "should allow you to find a query a conversion" do
    now = DateTime.now
    Conversion.create(:client_id => 1, :channel_id => "google", :goal_name=> "Some Goal", :time => now)
    cons = Conversion.query([1, "google"]).all
    cons.size.should == 1
  end
  
  it "should allow you to find a query a conversion within a range" do
    now = DateTime.now
    Conversion.create(:client_id => 1, :channel_id => "google", :goal_name=> "Some Goal", :time => now - 3)
    Conversion.create(:client_id => 1, :channel_id => "google", :goal_name=> "Some Goal", :time => now - 2)
    Conversion.create(:client_id => 1, :channel_id => "google", :goal_name=> "Some Goal", :time => now - 1)
    cons = Conversion.query([1, "google"]).where(now, :lt).all
    cons.size.should == 3
    cons = Conversion.query([1, "google"]).where(now - 4, :gt).all
    cons.size.should == 3
    cons = Conversion.query([1, "google"]).where(now - 2, :gte).where(now, :lt).all
    cons.size.should == 2
  end
  
  
end