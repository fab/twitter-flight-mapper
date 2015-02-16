require 'twitter'
require 'tzinfo'
require 'csv'
require_relative 'airport_timezones'

include AirportTimezones

def setup
  @all_tweets = []

  @client = Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV['TWITTER_KEY']
    config.consumer_secret     = ENV['TWITTER_SECRET']
    config.access_token        = ENV['TWITTER_TOKEN']
    config.access_token_secret = ENV['TWITTER_TOKEN_SECRET']
  end
end

def flight_tweet?(tweet_text)
  # check if tweet text contains '->'
  /-&gt/ === tweet_text
end

def parse_tweet_attributes(tweet)
  tweet_text = tweet.text

  origin, destination = tweet_text.scan(/\w\w\w/)
  timezone_name = AirportTimezones.list[origin]
  timezone = TZInfo::Timezone.get(timezone_name)
  tweet_date_utc = tweet.created_at
  tweet_date = timezone.utc_to_local(tweet_date_utc).strftime('%Y-%m-%d')
  tweet_id = tweet.id

  {id: tweet_id, origin: origin, destination: destination, date: tweet_date}
end

def check_first_200_tweets
  @client.user_timeline('fabsays', {count: 200}).each do |tweet|
    if flight_tweet?(tweet.text)
      tweet_hash = parse_tweet_attributes(tweet)
      @all_tweets << tweet_hash
    end
  end
end

def page_past_first_200_tweets
  number_of_tweets_on_this_request = nil

  until number_of_tweets_on_this_request == 0 do
    number_of_tweets_on_this_request = 0
    max_id = @all_tweets.last[:id] - 1

    @client.user_timeline('fabsays', {count: 200, max_id: max_id}).each do |tweet|
      if flight_tweet?(tweet.text)
        tweet_hash = parse_tweet_attributes(tweet)
        @all_tweets << tweet_hash
        number_of_tweets_on_this_request += 1
      end
    end
  end
end

def output_tweets_to_console
  @all_tweets.each do |tweet|
    puts "Tweet ID: #{tweet[:id]}"
    puts "You flew from #{tweet[:origin]} to #{tweet[:destination]} on #{tweet[:date]}"
  end

  puts "Total Flights: #{@all_tweets.length}"
end

def export_tweets_to_csv
  CSV.open('flights.csv', "wb") do |csv|
    csv << CSV.read('import_headers.csv').first
    @all_tweets.each do |tweet|
      csv << [tweet[:date], tweet[:origin], tweet[:destination]]
    end
  end

  puts "CSV of flight tweets generated."
end

setup
check_first_200_tweets
page_past_first_200_tweets
output_tweets_to_console
export_tweets_to_csv
