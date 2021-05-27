class ShortUrlsController < ApplicationController

  # Since we're working on an API, we don't have authenticity tokens
  skip_before_action :verify_authenticity_token

  def index
    render json: {urls: ShortUrl.limit(100).order("click_count DESC")}
  end

  def create
    new_url = ShortUrl.new(full_url: params[:full_url])
    if new_url.save
        render json: {short_code: '12345'}, status: :created
    else
        render json: {errors: new_url.errors.full_url}, status: :unprocessable_entity
    end
  end

  def show
  end

end
