require 'spec_helper'

describe Mongoid::Sessions do
  before do
    Mongoid::Sessions.instance_variable_set('@session_pool', nil)
  end

  describe 'default' do
    let(:default_pool) do
      Mongoid::Sessions.instance_variable_get('@session_pool')[:default]
    end

    it "should take a default session from pool" do
      expect(Mongoid::Sessions.default).to be_a Moped::Session
      expect(default_pool.reserved_sessions).to_not be_nil
    end
  end

  describe '.disconnect' do
    it "does not lock up when no sessions are created" do
      expect(Mongoid::Sessions.disconnect).to_not raise_error
    end
  end
end
