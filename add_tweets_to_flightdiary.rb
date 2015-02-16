# Require the gems
require 'tweetstream'
require 'capybara/poltergeist'
require 'tzinfo'
require_relative 'airport_timezones'

include AirportTimezones

# Configure TweetStream to use my OAuth tokens
TweetStream.configure do |config|
  config.consumer_key        = ENV['TWITTER_KEY']
  config.consumer_secret     = ENV['TWITTER_SECRET']
  config.oauth_token         = ENV['TWITTER_TOKEN']
  config.oauth_token_secret  = ENV['TWITTER_TOKEN_SECRET']
  config.auth_method         = :oauth
end

# Configure Poltergeist to not blow up on websites with js errors aka every website with js
# See more options at https://github.com/teampoltergeist/poltergeist#customization
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false)
end

# Configure Capybara to use Poltergeist as the driver
Capybara.default_driver = :poltergeist

# Use TweetStream to monitor a live stream of my tweets
client = TweetStream::Client.new

# Listen to each tweet from just my account
client.userstream(with: 'user') do |tweet|
  tweet_text = tweet.text
  puts tweet_text
  if /-&gt/ === tweet_text  # check if tweet text contains '->'
    origin, destination = tweet_text.scan(/\w\w\w/)
    timezone_name = AirportTimezones.list[origin]
    timezone = TZInfo::Timezone.get(timezone_name)
    date_utc = tweet.created_at
    date = timezone.utc_to_local(date_utc).strftime('%Y-%m-%d')
    puts "You flew from #{origin} to #{destination} on #{date}"

    # Create new Capybara session with Poltergeist as the driver
    browser = Capybara::Session.new(:poltergeist)

    # Use Capybara to crawl pages on FlightDiary
    url = "http://flightdiary.net/"
    browser.visit url

    # Sign in to FlightDiary with my credentials
    browser.find('.sign-in-button').click
    browser.fill_in 'username', with: 'fabm'
    browser.fill_in 'password', with: 'qaqaqa' # Make this ENV['FLIGHTDIARY_PASSWORD']
    browser.click_button 'Sign in'

    # Go to Add flight page
    browser.find_link('Add flight').click

    # Fill in form with flight tweet details
    browser.fill_in 'departure-date',    with: date
    browser.fill_in 'flight-number' ,    with: ' '    # Can't be blank
    browser.fill_in 'departure-airport', with: origin
    browser.fill_in 'arrival-airport',   with: destination

    # Give site time to populate the autocomplete fields before submitting
    sleep 5
    browser.click_button 'Add flight'

    # End Capybara session
    browser.driver.quit
  end
end
