require "open-uri"

class UpdateTitleJob < ApplicationJob
  queue_as :default

  def perform(short_url_id)
    @short_url = ShortUrl.find_by(id: short_url_id)
    @short_url.update_title!
  end
end
