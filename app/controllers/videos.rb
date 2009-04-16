class Videos < Application
  # provides :xml, :yaml, :js

  def index
    @videos = Video.all
    display @videos
  end

  def show(id)
    @video = Video.get(id)
    raise NotFound unless @video
    display @video
  end

  def create(video)
    @video = Video.new(video)
    if @video.save
      redirect resource(@video), :message => {:notice => "Video was successfully created"}
    else
      message[:error] = "Video failed to be created"
      render :new
    end
  end
end # Videos
