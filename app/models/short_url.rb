require 'uri'
class ShortUrl < ApplicationRecord

  CHARACTERS = [*'0'..'9', *'a'..'z', *'A'..'Z'].freeze

  validate :validate_full_url

  def short_code
  end

  def update_title!
  end

  private

  def validate_full_url
    uri = URI.parse(full_url)
    unless uri.is_a?(URI::HTTP) && !uri.host.nil?
        print 'URI ERROR'
        errors.add(:full_url, "Full url is not a valid url")
    end
  end

end
