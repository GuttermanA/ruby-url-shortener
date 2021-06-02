class ShortUrl < ApplicationRecord
  include ActiveModel::Serializers::JSON
  CHARACTERS = [*"0".."9", *"a".."z", *"A".."Z"].freeze
  BASE = CHARACTERS.length
  validates :full_url, uniqueness: { case_sensitive: false, message: "Full url already exists" }, presence: { message: "can't be blank" }
  validate :validate_full_url, on: :create
  after_create :async_update_title!, :update_short_code!

  def public_attributes
    self.as_json
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
    self.find_by(short_code: short_code)
  end

  def self.find_by_short_code_and_update_clicks!(id)
    short_url = ShortUrl.find_by_short_code(id)
    if short_url
      short_url.click_count += 1
      short_url.save
    end
    short_url
  end

  def is_taken_error?
    full_url_errors = self.errors&.details.dig(:full_url)
    return false if full_url_errors.nil?
    full_url_errors.any? { |hash| hash[:error] == :taken }
  end

  def update_short_code!
    # encode the full_url and append the db id to ensure no collisions and fulfill the requirment that the short_code length "is relative to the number of links currently in the system"
    short_code = ShortUrl.encode_str_6(self.full_url) + ShortUrl.encode(self.id)
    self.short_code = short_code
    self.save
    self.short_code
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
    return CHARACTERS[num] if num == 0
    short_url = ""
    while num > 0
      short_url = CHARACTERS[num % BASE] + short_url
      num = num / BASE
    end
    short_url
  end

  def self.decode(base62str)
    id = 0
    chars.each_char.with_index { |c, index|
      pow = BASE ** (chars.length - index - 1)
      id += CHARACTERS.index(c) * pow
    }
    id
  end

  def self.encode_str_6(str)
    #convert string to hex so it can easily be converted to decimal
    hex = str.unpack("H*").first
    #convert hex to integer so it can be encoded using our algorithm
    int = hex.to_i(16)
    # use encoding function and take first 6 chars of the ecoded value
    ShortUrl.encode(int)[0..6]
  end

  def self.decode_to_str(base62str)
    #decode encoded int
    decoded = ShortUrl.decode(base62str)
    #int to hex
    hex = decoded.to_s(16)
    #hex to str
    [hex].pack("H*")
  end
end
