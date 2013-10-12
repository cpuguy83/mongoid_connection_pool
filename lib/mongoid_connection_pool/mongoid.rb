require 'thread'
require 'thread_safe'
require 'monitor'
require_relative 'mongoid/config'
require_relative 'mongoid/sessions'

module Mongoid
  def with_session(&block)
    Sessions.with_session(&block)
  end
end
