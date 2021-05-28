require "uri"

class ShortUrl < ApplicationRecord
  CHARACTERS = [*"0".."9", *"a".."z", *"A".."Z"].freeze
  BASE = CHARACTERS.length
  validates :full_url, uniqueness: { case_sensitive: false }, presence: { message: "can't be blank" }
  validate :validate_full_url

  after_create :update_title!

  def short_code
    encode
  end

  def update_title!
    UpdateTitleJob.perform_later(self.id)
  end

  private

  def validate_full_url
    uri = URI.parse(full_url)
    unless uri.is_a?(URI::HTTP) && !uri.host.nil?
      errors.add(:full_url, "Full url is not a valid url")
    end
  rescue
    errors.add(:full_url, "is not a valid url")
  end

  def self.encode(num)
    short_url = ""
    while num > 0
      short_url = CHARACTERS[num % BASE] + short_url
      num = num / BASE
    end
    puts short_url
    short_url
  end
end
