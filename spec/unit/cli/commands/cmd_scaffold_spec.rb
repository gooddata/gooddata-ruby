require 'fileutils'

require 'gooddata/cli/cli'

describe GoodData::CLI do
  TEST_PROJECT_NAME = 'test-project'
  TEST_BRICK_NAME = 'test-brick'

  it "Has working 'scaffold' command" do
    args = %w(scaffold)

    run_cli(args)
  end

  it "Has working 'scaffold brick' command" do
    args = %w(scaffold brick)

    run_cli(args)
  end

  it "Has working 'scaffold project' command" do
    args = %w(scaffold project)

    run_cli(args)
  end

  it "Has working 'scaffold brick <brick-name>' command" do
    args = [
      'scaffold',
      'brick',
      TEST_BRICK_NAME
    ]

    run_cli(args)
    FileUtils.rm_rf(TEST_BRICK_NAME)
  end

  it "Has working 'scaffold project <project-name>' command" do
    args = [
      'scaffold',
      'project',
      TEST_PROJECT_NAME
    ]

    run_cli(args)
    FileUtils.rm_rf(TEST_PROJECT_NAME)
  end
end