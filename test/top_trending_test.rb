require "test_helper"

class TopTrendingTest < Minitest::Test
  def setup
    @client = TopTrending::Client.new(redis_client: Redis.new,
                                      leaderboard_name: 'top_trending_words',
                                      hours_or_seconds: :seconds)
  end

  def teardown
    @client.flushall
  end

  def test_that_it_has_a_version_number
    refute_nil ::TopTrending::VERSION
  end

  def test_it_does_redissy_stuff_via_delegation
    @client.set('this', 'that')
    assert_equal @client.get('this'), 'that'
  end

  def test_keeps_track_of_the_leader
    5.times { @client.bump_score('egg') }
    4.times { @client.bump_score('dog') }
    3.times { @client.bump_score('cat') }
    2.times { @client.bump_score('banana') }
    1.times { @client.bump_score('apple') }

    assert_equal @client.leaderboard, ['egg', 'dog', 'cat', 'banana', 'apple']

    5.times { @client.bump_score('apple') }

    assert_equal @client.leaderboard, ['apple', 'egg', 'dog', 'cat', 'banana']

    9.times { @client.bump_score('cat') }
    9.times { @client.bump_score('banana') }

    assert_equal @client.leaderboard, ['cat', 'banana', 'apple', 'egg', 'dog']
  end

  def test_expiry_of_old_time_slices
    10.times { @client.bump_score('zoo') }

    sleep 1

    10.times { @client.bump_score('yak') }

    sleep 1

    5.times { @client.bump_score('egg') }
    4.times { @client.bump_score('dog') }
    3.times { @client.bump_score('cat') }
    2.times { @client.bump_score('banana') }
    1.times { @client.bump_score('apple') }

    sleep 8

    assert_equal @client.leaderboard, ['zoo', 'yak', 'egg', 'dog', 'cat', 'banana', 'apple']

    sleep 14

    msg = "Oldest slice should timeout"
    assert_equal @client.leaderboard, ['yak', 'egg', 'dog', 'cat', 'banana', 'apple'], msg

    sleep 1

    msg = "Next oldest slice should timeout"
    assert_equal @client.leaderboard, ['egg', 'dog', 'cat', 'banana', 'apple'], msg

    sleep 1

    msg = "All keys visible keys should have expired"
    assert_equal @client.leaderboard, [], msg

    sleep 3
    msg = "All keys should have expired, freeing up memory"
    assert_equal @client.dbsize, 0, msg
  end
end
