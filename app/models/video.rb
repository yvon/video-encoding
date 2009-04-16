require 'rubygems'
require 'aws/s3'
require 'net/http'
require 'uri'

class Video
  include DataMapper::Resource
  
  timestamps  :created_at
  property    :id,                Serial
  property    :sent_to_heywatch,  Boolean
  property    :filename,          String
  property    :video_id,          Integer
  property    :original,          String
  property    :size,              Integer
  property    :content_type,      String
    
  def tempfile=(file)
    @tempfile = file
  end
  
  def upload_to_s3
    # TODO: Push in conf file
    AWS::S3::Base.establish_connection!(
      :access_key_id     => S3[:access_key_id],
      :secret_access_key => S3[:secret_access_key]
    ) unless AWS::S3::Base.connected?
    
    AWS::S3::S3Object.store(s3_object, @tempfile, original_bucket, :access => :public_read)
    self.original = public_url and self.save!
  end
  
  def from_s3_to_heywatch    
    url = ::URI.parse('http://heywatch.com/download.xml')
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth HEYWATCH[:login], HEYWATCH[:password]
    
    req.set_form_data(
      :url => self.original,
      :title => title,
      :format_id => '31',
      :automatic_encode => 'true',
      :ping_url_after_encode => "http://yewidho.com:4000/videos/#{self.video_id}/encoded"
    )
    
    resp = Net::HTTP.new( url.host, url.port ).start{ |http| http.request( req )}
    raise HeywatchEncodeError, 'Heywatch unable to download video' unless resp.code == '201'
    self.sent_to_heywatch = true and self.save!
  end
  
  private
    def s3_object
      @s3_object ||= title + File.extname(self.filename)
    end
    
    def title
      @title ||= "#{self.id}_#{random_digits}"
    end
    
    def random_digits
      Array.new(5) { rand(10) }.join
    end
  
    def original_bucket
      S3[:buckets][:original_videos]
    end
    
    def encoded_bucket
      S3[:buckets][:encoded_videos]
    end
  
    def public_url
      "http://s3.amazonaws.com/#{original_bucket}/#{s3_object}"
    end
end
