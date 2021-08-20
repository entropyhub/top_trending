require "test_helper"

class TopTrendingTest < Minitest::Test
  def setup
    @client = TopTrending::Client.new(redis_client: Redis.new,
                                      leaderboard_name: 'top_trending_words')
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

    assert_equal ['egg', 'dog', 'cat', 'banana', 'apple'], @client.leaderboard

    5.times { @client.bump_score('apple') }

    assert_equal ['apple', 'egg', 'dog', 'cat', 'banana'], @client.leaderboard

    9.times { @client.bump_score('cat') }
    9.times { @client.bump_score('banana') }

    assert_equal ['cat', 'banana', 'apple', 'egg', 'dog'], @client.leaderboard
    assert_equal({'cat' => 12, 'banana' => 11, 'apple' => 6, 'egg' => 5, 'dog' => 4 }, @client.scores)
  end

  def test_expiry_of_old_time_slices
    Timecop.travel(Time.local(2021, 1, 1, 0))
    10.times { @client.bump_score('zoo') }

    Timecop.travel(Time.local(2021, 1, 1, 3))

    9.times { @client.bump_score('yak') }

    Timecop.travel(Time.local(2021, 1, 1, 6))

    5.times { @client.bump_score('egg') }
    4.times { @client.bump_score('dog') }
    3.times { @client.bump_score('cat') }
    2.times { @client.bump_score('banana') }
    1.times { @client.bump_score('apple') }

    Timecop.travel(Time.local(2021, 1, 1, 10))

    msg = "Counts correctly"
    assert_equal @client.leaderboard, ['zoo', 'yak', 'egg', 'dog', 'cat', 'banana', 'apple'], msg

    Timecop.travel(Time.local(2021, 1, 2, 3))

    msg = "Oldest slice should timeout"
    assert_equal @client.leaderboard, ['yak', 'egg', 'dog', 'cat', 'banana', 'apple'], msg

    Timecop.travel(Time.local(2021, 1, 2, 4))

    msg = "Next oldest slice should timeout"
    assert_equal @client.leaderboard, ['egg', 'dog', 'cat', 'banana', 'apple'], msg

    Timecop.travel(Time.local(2021, 1, 3, 0))

    msg = "All keys visible keys should have expired"
    assert_equal @client.leaderboard, [], msg
  end
end
