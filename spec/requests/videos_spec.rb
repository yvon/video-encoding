require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a video exists" do
  Video.all.destroy!
  request(resource(:videos), :method => "POST", 
    :params => { :video => { :id => nil }})
end

describe "resource(:videos)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:videos))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of videos" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a video exists" do
    before(:each) do
      @response = request(resource(:videos))
    end
    
    it "has a list of videos" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Video.all.destroy!
      @response = request(resource(:videos), :method => "POST", 
        :params => { :video => { :id => nil }})
    end
    
    it "redirects to resource(:videos)" do
      @response.should redirect_to(resource(Video.first), :message => {:notice => "video was successfully created"})
    end
    
  end
end

describe "resource(@video)" do 
  describe "a successful DELETE", :given => "a video exists" do
     before(:each) do
       @response = request(resource(Video.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:videos))
     end

   end
end

describe "resource(:videos, :new)" do
  before(:each) do
    @response = request(resource(:videos, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@video, :edit)", :given => "a video exists" do
  before(:each) do
    @response = request(resource(Video.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@video)", :given => "a video exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Video.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @video = Video.first
      @response = request(resource(@video), :method => "PUT", 
        :params => { :video => {:id => @video.id} })
    end
  
    it "redirect to the video show action" do
      @response.should redirect_to(resource(@video))
    end
  end
  
end

