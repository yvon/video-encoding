class Videos < Application
  def index
    @videos = Video.all
    display @videos
  end

  def show(id)
    @video = Video.get(id)
    raise NotFound unless @video
    display @video
  end

  def create(file, video_id)    
    @video = Video.new(file.merge(:video_id => video_id))
    if @video.save
      run_later do
        @video.upload_to_s3
        @video.from_s3_to_heywatch
      end
      render "OK", :status => 200
    else
      render "KO", :status => 500
    end
  end
end # Videos
