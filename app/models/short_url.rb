class ShortUrl < ApplicationRecord
  include ActiveModel::Serializers::JSON
  CHARACTERS = [*"0".."9", *"a".."z", *"A".."Z"].freeze
  BASE = CHARACTERS.length
  validates :full_url, uniqueness: { case_sensitive: false, message: "Full url already exists" }, presence: { message: "can't be blank" }
  validate :validate_full_url, on: :create
  after_create :async_update_title!

  def public_attributes
    self.as_json
  end

  def short_code
    ShortUrl.encode(self.id)
  end

  def update_title!
    doc = Nokogiri::HTML(URI.open(self.full_url))
    self.title = doc.at_css("title").text
    self.save!
  end

  def async_update_title!
    UpdateTitleJob.perform_later(self.id)
  end

  def self.find_by_short_code(short_code)
    @id = self.decode(short_code)
    self.find_by(id: @id)
  end

  def is_taken_error?
    full_url_errors = self.errors&.details.dig(:full_url)
    return false if full_url_errors.nil?
    full_url_errors.any? { |hash| hash[:error] == :taken }
  end

  private

  def attributes
    {
      "full_url" => nil,
      "click_count" => nil,
      "title" => nil,
    }
  end

  def validate_full_url
    message = "Full url is not a valid url"
    uri = URI.parse(full_url)
    unless uri.is_a?(URI::HTTP) && !uri.host.nil?
      errors.add(:full_url, message)
    end
  rescue
    errors.add(:full_url, message)
  end

  def self.encode(num)
    return nil if num == nil || num < 0
    return "0" if num == 0
    short_url = ""
    while num > 0
      short_url = CHARACTERS[num % BASE] + short_url
      num = num / BASE
    end
    short_url
  end

  def self.decode(chars)
    id = 0
    chars.each_char.with_index { |c, index|
      pow = BASE ** (chars.length - index - 1)
      id += CHARACTERS.index(c) * pow
    }
    id
  end
end
