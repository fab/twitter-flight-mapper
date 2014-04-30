require 'twitter'

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_KEY']
  config.consumer_secret     = ENV['TWITTER_SECRET']
  config.access_token        = ENV['TWITTER_TOKEN']
  config.access_token_secret = ENV['TWITTER_TOKEN_SECRET']
end

client.user_timeline('fabsays', {count: 200}).each do |tweet|
  tweet_text = tweet.text
  tweet_id = tweet.id
  if /-&gt/ === tweet_text  # check if tweet text contains '->'
    origin, destination = tweet_text.scan(/\w\w\w/)
    tweet_date = tweet.created_at.strftime('%b %d %Y')
    puts "You flew from #{origin} to #{destination} on #{tweet_date}"
  end
end
