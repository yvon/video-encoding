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

  def create(file)    
    @video = Video.new(file)
    if @video.save
      render "OK", :status => 200
    else
      render "KO", :status => 500
    end
  end
end # Videos
