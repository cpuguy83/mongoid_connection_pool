module Mongoid
  module Config
    option :session_pool_size, :default        => 5
    option :session_checkout_timeout, :default => 5
    option :session_reap_frequency, :default   => 3
  end
end
