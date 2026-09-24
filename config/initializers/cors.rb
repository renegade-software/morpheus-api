Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Comma-separated, so production can add the Render URL without a code change.
    origins ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(",")

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
