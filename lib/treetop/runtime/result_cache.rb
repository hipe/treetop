module Treetop
  module Runtime
    class ResultCache
      attr_reader :results
      
      def initialize
        @result_index = Hash.new {|h, k| h[k] = Hash.new }
        @results = []
      end

      def store_result(rule_name, result)
        result.memoizations.push(Memoization.new(rule_name, result, result_index))
        result.retain(self)
      end

      def get_result(rule_name, start_index)
        result_index[rule_name][start_index]
      end

      def has_result?(rule_name, start_index)
        result_index[rule_name].has_key?(start_index)
      end

      def expire(range, length_change)
        detect_and_expire_intersected_results(range)
        release_expired_memoizations
        relocate_remaining_results(range, length_change)
      end

      def schedule_memoization_expiration(memoization)
        memoizations_to_expire.push(memoization)
      end

      def inspect
        s = ""
        result_index.each do |rule_name, subhash|
          s += "#{rule_name}: "
          subhash.each do |i, v|
            s += "#{i} => #{v.inspect}, "
          end
          s += "\n"
        end
        s
      end

      protected

      attr_reader :result_index, :memoizations_to_expire

      def detect_and_expire_intersected_results(range)
        @memoizations_to_expire = []
        results.each do |result|
          result.expire if result.interval.intersects?(range)
        end
      end

      def release_expired_memoizations
        memoizations_to_expire.uniq.each do |memoization|
          memoization.expire
        end
      end

      def relocate_remaining_results(range, length_change)
        results.each do |result|
          result.relocate(length_change) if result.interval.first >= range.last
        end
      end
    end
  end
end