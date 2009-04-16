class Video
  include DataMapper::Resource
  
  property :id, Serial

  property :heywatch_id, Integer
  property :encoded, String
  property :filename, String
  property :revelatr_id, Integer
  property :original, String
  property :size, Integer
  
  def content_type=(value)
    nil
  end
  
  def tempfile=(file)
    nil
  end
end
