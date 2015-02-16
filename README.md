Twitter Flight Mapper
=====================
This is a two-part project to help me keep better track of my flights.

Whenever I take a flight I always make sure to tweet `Origin -> Destination` using the correct three-letter IATA airport code for both `Origin` and `Destination`. Eg: `SFO -> LAX`

`export_tweets_to_csv.rb` pulls all my previous flight tweets and puts them into a CSV for importing into [Flightdiary](http://flightdiary.net).

`add_tweets_to_flightdiary.rb` is using the Twitter Streaming API to continuously listen to my tweets and when it detects that I've posted about a flight it will use [Capybara](https://github.com/jnicklas/capybara) and [PhantomJS](http://phantomjs.org/) to go and add it to Flightdiary. This piece of code is currently running on a [Heroku](http://heroku.com/) dyno.

The result of this project is that I now have a [Flightdiary profile](http://flightdiary.net/fabm) full of data that continually updates itself as long as I make sure to tweet my flights.
