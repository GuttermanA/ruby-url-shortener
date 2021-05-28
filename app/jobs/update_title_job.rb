require "open-uri"

class UpdateTitleJob < ApplicationJob
  queue_as :default

  def perform(short_url_id)
    puts short_url_id
    @short_url = ShortUrl.find_by(id: short_url_id)
    doc = Nokogiri::HTML(URI.open(@short_url.full_url))
    @short_url.title = doc.at_css("title").text
    @short_url.save!
  end
end
