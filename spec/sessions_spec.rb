describe Mongoid::Sessions do
  describe '.disconnect' do
    it "does not lock up when no sessions are created" do
      Mongoid::Sessions.instance_variable_set('@session_pool', nil)
      expect(Mongoid::Sessions.disconnect).to_not raise_error
    end
  end
end
