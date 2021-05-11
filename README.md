# Top Trending

Measures the top trending terms or events over a 24 hour period.

For example, a dictionary site might want to record the top trending words looked up by visitors. 

![screenshot](https://github.com/entropyhub/top_trending/blob/master/trending_words.png)

The implementation leverages a Redis backend to collate and expire data, which
may avoid the heavy data processing involved in a more naive implementation.

## Usage

``` ruby
    @client = TopTrending::Client.new(redis_client: Redis.new,
                                      leaderboard_name: 'top_trending_words')

    3.times { @client.bump_score('cat') }
    2.times { @client.bump_score('banana') }
    1.times { @client.bump_score('apple') }

    @client.leaderboard
    # => ['cat', 'banana', 'apple']
```

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'top_trending'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install top_trending

## Development

To understand how this works, checkout [https://youtu.be/XqSK-4oEoAc](Redis Sorted Sets Explained).

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/top_trending.

