module TopTrending
  class Client < SimpleDelegator
    def initialize(redis_client:, leaderboard_name:, hours_or_seconds: :hours)
      super(redis_client)
      @redis = redis_client
      @leaderboard_name = leaderboard_name
      @expiry_already_set = Set.new
      case hours_or_seconds
      when :hours # Record the "Top Trending" in the last 24 hour period
        @slice_time = 1 * 60 * 60 # Seconds in an hour
      when :seconds # For testing
        @slice_time = 1
      else
        raise ArgumentError
      end
    end

    def bump_score(entity)
      key = current_key
      zincrby(key, 1, entity)
      expire(key, expiry_time)
    end

    def leaderboard
      top(10)
    end

    private

    def top(n)
      totals_key = key('totals')
      zunionstore(totals_key, last_24_keys)
      zrevrange(totals_key, 0, n)
    end

    def key(slice)
      "#{@leaderboard_name}:#{slice}".tap { |key| set_expiry(key) }
    end

    def current_key
      key(Time.now.to_i / @slice_time)
    end

    # Key expiry time in seconds
    def expiry_time
      @slice_time * 26 # keep 26 slices around, but we only ever interrogate 24
    end

    def set_expiry(key)
      unless @expiry_already_set.include?(key)
        @expiry_already_set.add(key)
        expire(key, expiry_time)
      end
    end

    def last_24_keys
      last_keys(24)
    end

    def last_keys(n)
      t = Time.now.to_i
      Array.new(n)
        .map
        .with_index { |_x, i | (t / @slice_time) - (i * @slice_time) }
        .map { |key| key(key)}
    end
  end
end
