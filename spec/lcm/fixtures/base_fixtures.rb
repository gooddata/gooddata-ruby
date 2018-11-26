module Fixtures
  class BaseFixtures
    FIXTURE_ID_PREFIX = 'lcm-test-fixture-'

    def teardown
      @teardown.call if @teardown
    end

    def [](key)
      @objects[key]
    end
  end
end
