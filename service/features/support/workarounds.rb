module WorkaroundHelpers
  def add_assertion
    # This exists because using any of the assert_* functions in plain cucumber fails
  end
end

World(WorkaroundHelpers)
