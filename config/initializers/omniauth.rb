Rails.application.config.middleware.use OmniAuth::Builder do
  provider :mendeley, ENV['MENDELEY_KEY'], ENV['MENDELEY_SECRET']
end