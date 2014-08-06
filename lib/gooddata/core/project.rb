# encoding: UTF-8

module GoodData
  @project = nil

  attr_reader :project

  class << self
    # Sets the active project
    #
    # @param project A project identifier
    #
    # ### Examples
    #
    # The following calls are equivalent
    #
    #     # Assign project ID
    #     GoodData.project = 'afawtv356b6usdfsdf34vt'
    #
    #     # Use project ID
    #     GoodData.use 'afawtv356b6usdfsdf34vt'
    #
    #     # Use project URL
    #     GoodData.use '/gdc/projects/afawtv356b6usdfsdf34vt'
    #
    #     # Select project using indexer on GoodData::Project class
    #     GoodData.project = Project['afawtv356b6usdfsdf34vt']
    # Assigns global/default GoodData project
    def project=(project)
      @project = project
      @project
    end

    alias_method :use, :project=

    # Returns the active project
    #
    # def project
    #   threaded[:project]
    # end

    # Perform block in context of another project than currently set
    #
    # @param project Project to use
    # @param bl Block to be performed
    def with_project(project, &bl)
      fail 'You have to specify a project when using with_project' if project.nil? || (project.is_a?(String) && project.empty?)
      old_project = GoodData.project
      begin
        GoodData.use(project)
        bl.call(GoodData.project)
      rescue RestClient::ResourceNotFound
        raise(GoodData::ProjectNotFound, 'Project was not found')
      ensure
        GoodData.project = old_project
      end
    end
  end
end
