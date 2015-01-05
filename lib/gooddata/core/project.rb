# encoding: UTF-8

module GoodData
  @project = nil

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
    def project=(project, opts = { :client => GoodData.connection })
      if project.is_a? Project
        @project = project
      elsif project.nil?
        @project = nil
      else
        @project = Project[project, opts]
      end
      @project
    end

    alias_method :use, :project=

    attr_reader :project

    # Returns the active project
    #
    # def project
    #   threaded[:project]
    # end

    # Perform block in context of another project than currently set
    #
    # @param project Project to use
    # @param bl Block to be performed
    def with_project(project, opts = { :client => GoodData.connection }, &bl)
      fail 'You have to specify a project when using with_project' if project.nil? || (project.is_a?(String) && project.empty?)
      fail 'You have to specify block' unless bl
      old_project = GoodData.project

      begin
        GoodData.use(project, opts)
        res = bl.call(GoodData.project)
      rescue RestClient::ResourceNotFound
        GoodData.project = old_project
        raise(GoodData::ProjectNotFound, 'Project was not found')
      end

      GoodData.project = old_project

      res
    end
  end
end
