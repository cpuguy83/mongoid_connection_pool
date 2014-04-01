module Mongoid
  module Sessions
    class SessionPool
      class Queue
        class ConnectionTimeoutError < StandardError; end

        def initialize(lock=Monitor.new)
          @lock = lock
          @cond = @lock.new_cond
          @num_waiting = 0
          @queue = []
        end

        def any_waiting?
          synchronize do
            @num_waiting > 0
          end
        end

        def num_waiting
          synchronize do
            @num_waiting
          end
        end

        def add(session)
          synchronize do
            @queue.push session
            @cond.signal
          end
        end

        def remove
          synchronize do
            @queue.shift
          end
        end

        def poll(timeout = nil)
          synchronize do
            if timeout
              no_wait_poll || wait_poll(timeout)
            else
              no_wait_poll
            end
          end
        end

        def count
          @queue.count
        end

        private

        def synchronize(&block)
          @lock.synchronize(&block)
        end

        def any?
          !@queue.empty?
        end

        def can_remove_no_wait?
          @queue.size > @num_waiting
        end

        def no_wait_poll
          remove if can_remove_no_wait?
        end

        def wait_poll(timeout)
          @num_waiting += 1

          t0 = Time.now
          elapsed = 0
          loop do
            @cond.wait(timeout - elapsed)

            return remove if any?

            elapsed = Time.now - t0
            if elapsed >= timeout
              msg = 'Timed out waiting for database session'
              raise ConnectionTimeoutError, msg
            end
          end
        ensure
          @num_waiting -= 1
        end
      end

      include MonitorMixin

      attr_reader :sessions, :size, :reaper, :reserved_sessions, :available
      def initialize(opts={})
        super()

        opts[:name] ||= :default
        opts[:size] ||= 5
        opts[:checkout_timeout] ||= 5
        # Might be false, disables Reaper
        opts[:reap_frequency] = 3 if opts[:reap_frequency].nil?

        @reaper = Reaper.new(opts[:reap_frequency], self)
        @reaper.run

        @checkout_timeout = opts[:checkout_timeout]

        @size = opts[:size]
        @name = opts[:name]
        @sessions = []
        @reserved_sessions = ThreadSafe::Cache.new(:initial_capacity => @size)
        @available = Queue.new self
      end

      def checkout
        synchronize do
          unless (session = session_for(Thread.current))
            session = get_session
            reserve(session)
          end
          session
        end
      end

      # Returns a session back to the available pool
      def checkin(session)
        if session
          synchronize do
            @available.add session
            release(session)
          end
          true
        end
      end

      def clear(thread=nil)
        if thread
          disconnect(thread)
          @reserved_sessions.delete(thread) if session_for(thread)
          @sessions.pop
        else
          @reserved_sessions = {}
          @sessions = []
          @available = Queue.new self
        end
        @reserved_sessions
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

      def checkin_from_thread(thread)
        checkin session_for(thread)
        true
      end

      def count
        @available.count
      end

      def reap
        @reserved_sessions.keys.each do |thread|
          session = @reserved_sessions[thread]
          checkin(session) unless thread.alive?
        end
      end

      def session_for(thread)
        @reserved_sessions[thread]
      end


      private

      def reserve(session)
        @reserved_sessions[current_session_id] = session
      end

      def current_session_id
        Thread.current
      end

      def release(session)
        thread =  if @reserved_sessions[current_session_id] == session
                      current_session_id
                  else
                    @reserved_sessions.keys.find do |k|
                      @reserved_sessions[k] == session
                    end
                  end
        @reserved_sessions.delete thread if thread
      end

      def get_session
        # always double check the reaper is running, if we got forked after it starts we dont have a thread anymore
        @reaper.run unless @reaper.alive?
        if session = @available.poll
          session
        elsif @sessions.size < @size
          checkout_new_session
        else
          @available.poll(@checkout_timeout)
        end
      end

      def checkout_new_session
        session = new_session
        @sessions << session
        session
      end

      def new_session
        Factory.create(@name)
      end

      class ConnectionTimeoutError < StandardError; end

      def create_new_session
        Factory.create(@name)
      end

      class Reaper
        attr_reader :pool
        attr_reader :frequency
        attr_reader :reaper

        def initialize(frequency, pool)
          @frequency = frequency
          @pool = pool
        end

        def alive?
          return true unless frequency
          # under rbx 2.2.4 this now works, also works correctly under mri at latest patch levels
          reaper.alive?
        end

        def run
          return unless frequency
          @reaper = Thread.new(frequency, pool) do |t, p|
            while true
              sleep t
              p.reap
            end
          end
        end
      end
    end
  end
end

