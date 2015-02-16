require 'twitter'
require 'tzinfo'
require 'csv'
require_relative 'airport_timezones'

include AirportTimezones

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_KEY']
  config.consumer_secret     = ENV['TWITTER_SECRET']
  config.access_token        = ENV['TWITTER_TOKEN']
  config.access_token_secret = ENV['TWITTER_TOKEN_SECRET']
end

all_tweets = []

client.user_timeline('fabsays', {count: 200}).each do |tweet|
  tweet_text = tweet.text
  if /-&gt/ === tweet_text  # check if tweet text contains '->'
    origin, destination = tweet_text.scan(/\w\w\w/)
    timezone_name = AirportTimezones.list[origin]
    timezone = TZInfo::Timezone.get(timezone_name)
    tweet_date_utc = tweet.created_at
    tweet_date = timezone.utc_to_local(tweet_date_utc).strftime('%Y-%m-%d')
    tweet_id = tweet.id
    tweet_hash = {id: tweet_id, origin: origin, destination: destination, date: tweet_date}
    all_tweets << tweet_hash
  end
end

# Now do paging to see past first 200 tweets

while true
  tweets_on_this_request = []
  max_id = all_tweets.last[:id] - 1

  client.user_timeline('fabsays', {count: 200, max_id: max_id}).each do |tweet|
    tweet_text = tweet.text
    if /-&gt/ === tweet_text  # check if tweet text contains '->'
      origin, destination = tweet_text.scan(/\w\w\w/)
      timezone_name = AirportTimezones.list[origin]
      timezone = TZInfo::Timezone.get(timezone_name)
      tweet_date_utc = tweet.created_at
      tweet_date = timezone.utc_to_local(tweet_date_utc).strftime('%Y-%m-%d')
      tweet_id = tweet.id
      tweet_hash = {id: tweet_id, origin: origin, destination: destination, date: tweet_date}
      tweets_on_this_request << tweet_hash
    end
  end

  break if tweets_on_this_request.length == 0

  all_tweets.concat(tweets_on_this_request)
end

all_tweets.each do |tweet|
  puts "Tweet ID: #{tweet[:id]}"
  puts "You flew from #{tweet[:origin]} to #{tweet[:destination]} on #{tweet[:date]}"
end

puts "Total Flights: #{all_tweets.length}"


CSV.open('flights.csv', "wb") do |csv|
  csv << CSV.read('import_headers.csv').first
  all_tweets.each do |tweet|
    csv << [tweet[:date], tweet[:origin], tweet[:destination]]
  end
end
