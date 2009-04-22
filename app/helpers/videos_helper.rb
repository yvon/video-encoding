module Merb
  module VideosHelper
    def s3_link(uri)
      return nil unless uri
      %{<a href="#{uri}">S3</a>}
    end
  end
end # Merb