require 'tweetstream'
require 'capybara/poltergeist'
require 'tzinfo'
require_relative 'airport_timezones'

include AirportTimezones

def setup_tweetstream_client
  TweetStream.configure do |config|
    config.consumer_key        = ENV['TWITTER_KEY']
    config.consumer_secret     = ENV['TWITTER_SECRET']
    config.oauth_token         = ENV['TWITTER_TOKEN']
    config.oauth_token_secret  = ENV['TWITTER_TOKEN_SECRET']
    config.auth_method         = :oauth
  end

  @client = TweetStream::Client.new
end

def setup_capybara
  # Configure Poltergeist to not blow up on websites with js errors aka every website with js
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, js_errors: false)
  end

  Capybara.default_driver = :poltergeist
end

def setup
  setup_tweetstream_client
  setup_capybara
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

def stream_my_tweets
  # Listen to each tweet from my account
  @client.userstream(with: 'user') do |tweet|
    puts tweet.text
    if flight_tweet?(tweet.text)
      tweet_hash = parse_tweet_attributes(tweet)

      puts "You flew from #{tweet_hash[:origin]} to #{tweet_hash[:destination]} on #{tweet_hash[:date]}"

      crawl_flightdiary(tweet_hash)
    end
  end
end

def crawl_flightdiary(tweet_hash)
  initialize_browser
  navigate_to_flightdiary
  sign_in_to_flightdiary
  add_flight_to_flightdiary(tweet_hash)
  end_browser_session
end

def initialize_browser
  # Create new Capybara session with Poltergeist as the driver
  @browser = Capybara::Session.new(:poltergeist)
end

def navigate_to_flightdiary
  url = "http://flightdiary.net/"
  @browser.visit url
end

def sign_in_to_flightdiary
  @browser.find('.sign-in-button').click
  @browser.fill_in 'username', with: 'fabm'
  @browser.fill_in 'password', with: 'qaqaqa' # Make this ENV['FLIGHTDIARY_PASSWORD']
  @browser.click_button 'Sign in'
end

def add_flight_to_flightdiary(tweet_hash)
  # Go to Add flight page
  @browser.find_link('Add flight').click

  # Fill in form with flight tweet details
  @browser.fill_in 'departure-date',    with: tweet_hash[:date]
  @browser.fill_in 'flight-number' ,    with: ' '    # Can't be blank
  @browser.fill_in 'departure-airport', with: tweet_hash[:origin]
  @browser.fill_in 'arrival-airport',   with: tweet_hash[:destination]

  # Give site time to populate the autocomplete fields before submitting
  sleep 5
  @browser.click_button 'Add flight'
end

def end_browser_session
  @browser.driver.quit
end

setup
stream_my_tweets
