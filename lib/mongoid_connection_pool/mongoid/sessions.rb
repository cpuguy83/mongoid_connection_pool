require_relative 'sessions/session_pool'

module Mongoid
  module Sessions
    class << self
      def synchronize(&block)
        @lock ||= Mutex.new
        @lock.synchronize(&block)
      end

      def session_pool(name=:default)
        if !@session_pool || !@session_pool[name]
          synchronize do
            @session_pool ||= {}
            @session_pool[name] ||= SessionPool.new(
              :size             => Config.session_pool_size,
              :name             => name,
              :checkout_timeout => Config.session_checkout_timeout,
              :reap_frequency   => Config.session_reap_frequency)
          end
        end
        @session_pool[name]
      end

      def disconnect(thread=Thread.current)
        synchronize do
          @session_pool.try(:each) do |name, pool|
            if thread
              pool.session_for(thread).try(:disconnect)
            else
              pool.sessions.try(:each) { |session| session.disconnect }
            end
          end
        end
        true
      end

      def default
        with_name(:default)
      end

      def with_name(name)
        session_pool(name).session_for(Thread.current) ||
          session_pool(name).checkout
      end

      def with_session(name=:default)
        yield
      ensure
        reap_current_session(name)
      end

      private

      def reap_current_session(name, thread = Thread.current)
        session_pool(name).checkin_from_thread thread
        true
      end
    end
  end
end
