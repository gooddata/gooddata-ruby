# encoding: UTF-8

require_relative 'threaded'

module GoodData
  # Assigns global/default GoodData project
  def project=(project)
    GoodData.project = project
    GoodData.project
  end

  alias :use :project=

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
    #
    def project=(project)
      if project.is_a? Project
        threaded[:project] = project
      elsif project.nil?
        threaded[:project] = nil
      else
        threaded[:project] = Project[project]
      end
    end

    alias :use :project=

    # Returns the active project
    #
    def project
      threaded[:project]
    end

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
      rescue RestClient::ResourceNotFound => e
        fail GoodData::ProjectNotFound.new(e)
      ensure
        GoodData.project = old_project
      end
    end
  end
end