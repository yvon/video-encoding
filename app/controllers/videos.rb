class Videos < Application
  provides :html, :xml
  
  def index
    @videos = Video.all
    display @videos
  end

  def show(id)
    @video = Video.get(id)
    raise NotFound unless @video
    display @video
  end
  
  def encoded(id, encoded_video_id)
    @video = Video.get(id)
    @video.successfully_encoded = true
    @video.heywatch_id = encoded_video_id
    @video.save(nil)
    run_later do
      @video.get_encoded_version &&
        @video.get_thumbnail &&
        @video.ping_remote_application
    end
    render "OK", :status => 200
  end
  
  def error(id)
    @video = Video.get(id)
    @video.successfully_encoded = false
    @video.save(nil)
    render "OK", :status => 200
  end

  def create(file, video_id, application_domain)    
    @video = Video.new(file.merge(
      :video_id => video_id,
      :application_domain => application_domain
    ))

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
