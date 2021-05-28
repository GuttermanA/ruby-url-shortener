class ShortUrlsController < ApplicationController

  # Since we're working on an API, we don't have authenticity tokens
  skip_before_action :verify_authenticity_token

  def index
    @top_100 = ShortUrl.limit(100).order("click_count DESC")
    render json: { urls: @top_100 }
  end

  def create
    new_url = ShortUrl.new(full_url: params[:full_url])
    if new_url.save
      render json: { short_code: new_url.short_code }, status: :created
    else
      render json: { errors: new_url.errors[:full_url] }, status: :unprocessable_entity
    end
  end

  def show
    @short_url = ShortUrl.find_by_short_code(params[:id])
    if @short_url
      @short_url.click_count += 1
      @short_url.save
      redirect_to @short_url.full_url, format: :json
    else
      render json: { errors: "Not found" }, status: :not_found
    end
  end
end
