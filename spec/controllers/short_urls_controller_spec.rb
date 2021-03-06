require "rails_helper"

RSpec.describe ShortUrlsController, type: :controller do
  let(:parsed_response) { JSON.parse(response.body) }

  describe "index" do
    let!(:short_url) { ShortUrl.create(full_url: "https://www.test.rspec") }

    it "is a successful response" do
      get :index, format: :json
      expect(response.status).to eq 200
    end

    it "has a list of the top 100 urls" do
      get :index, format: :json

      expect(parsed_response["urls"]).to be_include(short_url.public_attributes)
    end

    it "provides the list of the top 100 urls in descending order" do
      low = 500
      med = 1286
      high = 30234
      ShortUrl.create(full_url: "https://www.gmail.com", click_count: low)
      ShortUrl.create(full_url: "https://www.reddit.com", click_count: med)
      ShortUrl.create(full_url: "https://www.seamless.com", click_count: high)
      get :index, format: :json
      expect(parsed_response["urls"].first["click_count"]).to eq high
      expect(parsed_response["urls"].second["click_count"]).to eq med
      expect(parsed_response["urls"].third["click_count"]).to eq low
      expect(parsed_response["urls"].fourth["click_count"]).to eq 0
    end
  end

  describe "create" do
    it "creates a short_url" do
      post :create, params: { full_url: "https://www.gmail.com" }, format: :json
      expect(response.status).to eq 201
      expect(parsed_response["short_code"]).to be_a(String)
    end

    it "if already exists, returns error and existing short_code" do
      short_url = ShortUrl.create(full_url: "https://www.test.rspec")
      post :create, params: { full_url: short_url.full_url }, format: :json
      expect(response.status).to eq 409
      expect(parsed_response["short_code"]).to be_a(String)
      expect(parsed_response["errors"]).to be_include("Full url already exists")
    end

    it "does not create a short_url" do
      post :create, params: { full_url: "nope!" }, format: :json
      expect(response.status).to eq 422
      expect(parsed_response["errors"]).to be_include("Full url is not a valid url")
    end
  end

  describe "show" do
    let!(:short_url) { ShortUrl.create(full_url: "https://www.test.rspec") }

    it "redirects to the full_url" do
      get :show, params: { id: short_url.short_code }, format: :json
      expect(response.status).to eq 302
      expect(response).to redirect_to(short_url.full_url)
    end

    it "does not redirect to the full_url" do
      get :show, params: { id: "nope" }, format: :json
      expect(response.status).to eq(404)
    end

    it "increments the click_count for the url" do
      expect { get :show, params: { id: short_url.short_code }, format: :json }.to change { ShortUrl.find(short_url.id).click_count }.by(1)
    end
  end
end
