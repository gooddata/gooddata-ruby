module GoodData
  class Datasets < Array
    def initialize(project, datasets = [])
      @project    = project
      @connection = project.connection
      datasets.each { |ds| self << ds }
    end

    def create_from_model(model)
      dataset = Dataset.remote connection, model
      dataset.save
      dataset
    end
  end
end