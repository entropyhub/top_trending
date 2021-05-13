module TopTrending
  class Client < SimpleDelegator
    def initialize(redis_client:,
                   leaderboard_name:,
                   hours_or_seconds: :hours,
                   number_of_items_in_leaderboard: 20)
      super(redis_client)
      @redis = redis_client
      @leaderboard_name = leaderboard_name
      @number_of_items_in_leaderboard = number_of_items_in_leaderboard
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
      return unless entity.is_a?(String) && !entity.empty?
      key = current_key
      zincrby(key, 1, entity)
      expire(key, expiry_time)
    end

    def leaderboard
      top(@number_of_items_in_leaderboard)
    end

    def get_state
      slices = last_keys(26).map do |slice|
        {
          key: slice,
          scores: zrevrange(slice, 0, 10, with_scores: true)
        }
      end

      {
        current_key: current_key,
        leaderboard: leaderboard,
        slices: slices,
      }
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
