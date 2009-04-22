module Merb
  module VideosHelper
    def s3_link(uri)
      %{<a href="#{uri}">S3</a>}
    end
  end
end # Merb