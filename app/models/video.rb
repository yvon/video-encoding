require 'rubygems'
require 'aws/s3'
require 'net/http'
require 'uri'
require 'open-uri'

class Video
  include DataMapper::Resource
  
  timestamps  :created_at
  property    :id,                    Serial
  property    :sent_to_heywatch,      Boolean
  property    :successfully_encoded,  Boolean
  property    :filename,              String,   :size => 100
  property    :video_id,              Integer
  property    :original,              String,   :size => 250
  property    :size,                  Integer
  property    :content_type,          String
  property    :encoded,               String,   :size => 250
  property    :thumbnail,             String,   :size => 250
  property    :application_domain,    String
  property    :heywatch_id,           Integer
  
  default_scope(:default).update(:order => [:created_at.desc], :limit => 100)
  
  def tempfile=(file)
    @tempfile = file
  end
  
  def ping_remote_application
    url = ::URI.parse("http://#{application_domain}/videos/#{video_id}/encoded")
    req = Net::HTTP::Post.new(url.path)
    
    req.set_form_data(
      :filename => self.filename,
      :original => self.original,
      :encoded => self.encoded,
      :thumbnail => self.thumbnail,
      :size => self.size
    )
    
    resp = Net::HTTP.new( url.host, url.port ).start{ |http| http.request( req )}
    raise unless resp.code == '200'
  end
  
  def get_encoded_version
    xml = heywatch_encoded_video

    file = Tempfile.new('video')
    
    video_link = xml[/<link>(.+)<\/link>/, 1]
    file.write(download_file_from_heywatch(video_link).read)
    
    # Hack => Flush the buffer
    file.close
    
    connect_to_s3
    
    AWS::S3::S3Object.store(title + '.flv', File.open(file.path), encoded_bucket, :access => :public_read)
    self.encoded = "http://s3.amazonaws.com/#{encoded_bucket}/#{title}.flv" and self.save!
  end
  
  def get_thumbnail
    xml = heywatch_encoded_video

    file = Tempfile.new('thumb')
    
    thumb_link = xml[/<thumb>(.+)<\/thumb>/, 1]
    file.write(download_file_from_heywatch(thumb_link).read)

    # Hack => Flush the buffer
    file.close
    
    connect_to_s3
    
    AWS::S3::S3Object.store(title + '.jpg', File.open(file.path), encoded_bucket, :access => :public_read)
    self.thumbnail = "http://s3.amazonaws.com/#{encoded_bucket}/#{title}.jpg" and self.save!
  end
  
  def upload_to_s3
    connect_to_s3
    
    AWS::S3::S3Object.store(s3_object, @tempfile, original_bucket, :access => :public_read)
    self.original = public_url and self.save!
  end
  
  def from_s3_to_heywatch    
    url = ::URI.parse('http://heywatch.com/download.xml')
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth ENV['HEYWATCH_LOGIN'], ENV['HEYWATCH_PASSWORD']
    
    req.set_form_data(
      :url => self.original,
      :title => title,
      :format_id => '31',
      :automatic_encode => 'true',
      :ping_url_after_encode => "http://#{ENV['HEYWATCH_PING_DOMAIN']}/videos/#{self.id}/encoded",
      :ping_url_if_error => "http://#{ENV['HEYWATCH_PING_DOMAIN']}/videos/#{self.id}/error"
    )
    
    resp = Net::HTTP.new( url.host, url.port ).start{ |http| http.request( req )}
    raise HeywatchEncodeError, 'Heywatch unable to download video' unless resp.code == '201'
    self.sent_to_heywatch = true and self.save!
  end
  
  private
    def connect_to_s3
      AWS::S3::Base.establish_connection!(
        :access_key_id     =>  ENV['S3_ACCESS_KEY_ID'],
        :secret_access_key =>  ENV['S3_SECRET_ACCESS_KEY']
      ) unless AWS::S3::Base.connected?
    end
  
    def download_file_from_heywatch(link)
      open( link,
        :http_basic_authentication => [ ENV['HEYWATCH_LOGIN'],
                                        ENV['HEYWATCH_PASSWORD'] ] )
    end
  
    def heywatch_encoded_video
      url = ::URI.parse("http://heywatch.com/encoded_video/#{heywatch_id}.xml")
      req = Net::HTTP::Get.new(url.path)
      req.basic_auth ENV['HEYWATCH_LOGIN'], ENV['HEYWATCH_PASSWORD']
      resp = Net::HTTP.new(url.host, url.port).start{ |http| http.request( req )}
      raise 'Heywatch unable to get video attributes' unless resp.code == '200'
      return(resp.body)
    end
  
    def s3_object
      return @s3_object if @s3_object
      extension = File.extname(self.filename)
      extension = ".mkv" if extension.empty?
      @s3_object = title + extension
    end
    
    def title
      return @title if @title
      @title = "#{self.id}_#{random_digits}"
    end
    
    def random_digits
      Array.new(5) { rand(10) }.join
    end
  
    def original_bucket
      ENV['S3_ORIGINAL_VIDEOS_BUCKET']
    end
    
    def encoded_bucket
      ENV['S3_ENCODED_VIDEOS_BUCKET']
    end
  
    def public_url
      "http://s3.amazonaws.com/#{original_bucket}/#{s3_object}"
    end
end
