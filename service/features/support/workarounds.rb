module WorkaroundHelpers
  def assert_equal(param1, param2)
    if not param1 == param2
      raise "Assertion failed: #{param1} == #{param2}"
    end
  end
end

World(WorkaroundHelpers)
