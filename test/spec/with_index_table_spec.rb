require File.join(File.dirname(__FILE__), *%w[spec_helper])

describe WithIndexTable do
  before(:all) do
    WithIndexTable.delete_table
  end
  before(:each) do
    WithIndexTable.query([1, "google"]).delete
  end
  
  it "should allow you to create a new row" do
    con = nil
    lambda{
      con = WithIndexTable.create(:client_id => 1, :channel_id => "google", :advert_id=> 1, :time => DateTime.now)
    }.should_not raise_error
    con.hash_key.should == "1|google" 
  end

  it "should allow you to have multiple rows for the same hash and range" do
    row1, row2 = nil
    time = DateTime.now
    lambda{
      row1 = WithIndexTable.create(:client_id => 1, :channel_id => "google", 
                                   :advert_id=> 1, :time => time)
      row2 = WithIndexTable.create(:client_id => 1, :channel_id => "google", 
                                   :advert_id=> 2, :time => time)
    }.should_not raise_error
    row1.hash_key.should == "1|google"
    row2.hash_key.should == "1|google"
  end

  it "should allow you to query for the some hash and range" do
    row1, row2 = nil
    time = DateTime.now
    lambda{
      row1 = WithIndexTable.create(:client_id => 1, :channel_id => "google", 
                                   :advert_id=> 1, :time => time)
      row2 = WithIndexTable.create(:client_id => 1, :channel_id => "google", 
                                   :advert_id=> 2, :time => time)
    }.should_not raise_error
    
    query = WithIndexTable.query([1, "google"]).where(time, :eq)
    query.size.should == 2
  
  end

end
