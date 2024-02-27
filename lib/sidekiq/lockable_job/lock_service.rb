require 'redis'

module Sidekiq::LockableJob
  module LockService
    class Error < StandardError; end

    REDIS_PREFIX_KEY = self.to_s.downcase

    def self.lock(key)
      redis.set(redis_key(key), Time.now.to_i)
    end

    def self.unlock(key)
      redis.del(redis_key(key))
    end

    def self.locked?(key)
      redis.exists(redis_key(key))
    end

    def self.handle_locked_by(keys, worker_instance:, job:)
      keys = [keys] unless keys.nil? || keys.is_a?(Array)
      keys&.each do |key|
        raise LockedJobError.new("Locked by #{key}") if locked?(key)
      end
      # job is not locked and should be processed
      false
    end

    def self.redis_key(key)
      "#{REDIS_PREFIX_KEY}:#{key}"
    end

    def self.redis
      Rails.cache.data
    end
  end
end
