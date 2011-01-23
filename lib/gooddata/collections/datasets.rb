module GoodData
  class Datasets < Array
    def initialize(project, datasets = [])
      @project    = project
      @connection = project.connection
      datasets.each { |ds| self << ds }
    end
  end
end