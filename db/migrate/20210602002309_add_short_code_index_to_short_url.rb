class AddShortCodeIndexToShortUrl < ActiveRecord::Migration[6.0]
  def change
    add_index :short_urls, :short_code
  end
end
