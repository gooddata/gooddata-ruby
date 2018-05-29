require 'gooddata'

module GoodData
  module AppStore
    module Helper
      def self.download_file_as_csv(project, filename)
        file = StringIO.new
        project.download_file(filename, file)
        CSV.parse(file.string)
      end

      def self.upload_file(project, data)
        begin
          tempfile = Tempfile.new('file_upload')
          path = tempfile.path

          CSV.open(path, 'w') do |csv|
            data.each { |row| csv << row}
          end
          project.upload_file(path)
        ensure
          tempfile.unlink
        end
        path
      end

      def self.remove_segment(domain, segment_name)
        begin
          domain.segments(segment_name).delete(force: true)
        rescue
          # Segment already deleted
        end
      end

      def self.remove_test_projects(client, slug)
        old_projects = client.projects.select do |project|
          project.title.include?(slug)
        end
        old_projects.peach(&:delete)
      end

      def self.create_simple_project(title, client, token)
        blueprint = GoodData::Model::ProjectBlueprint.build(title) do |p|
          p.add_date_dimension('committed_on')
          p.add_dataset('devs') do |d|
            d.add_anchor('attr.dev')
            d.add_label('label.dev_id', :reference => 'attr.dev')
            d.add_label('label.dev_email', :reference => 'attr.dev')
          end
          p.add_dataset('commits') do |d|
            d.add_anchor('attr.commits_id')
            d.add_fact('fact.lines_changed')
            d.add_date('committed_on')
            d.add_reference('devs')
          end
        end
        project = GoodData::Project.create_from_blueprint(blueprint, auth_token: token, client: client)

        # Load data
        commits_data = [
          ['fact.lines_changed', 'committed_on', 'devs'],
          [1, '01/01/2014', 1],
          [3, '01/02/2014', 2],
          [5, '05/02/2014', 3]]
        project.upload(commits_data, blueprint, 'commits')

        devs_data = [
          ['label.dev_id', 'label.dev_email'],
          [1, 'tomas@gooddata.com'],
          [2, 'petr@gooddata.com'],
          [3, 'jirka@gooddata.com']]
        project.upload(devs_data, blueprint, 'devs')

        # deploy process
        project.deploy_process('./spec/hello.rb', type: :ruby, name: 'some_process')
        project.deploy_process('./spec/hello.rb', type: :ruby, name: 'some_other_process')

        # create a metric
        metric = project.facts('fact.lines_changed').create_metric
        metric.lock
        metric.save

        report = project.create_report(title: 'Awesome_report', top: [metric], left: ['label.dev_email'])
        report.lock
        report.save

        ########################
        # Create new dashboard #
        ########################
        dashboard = project.create_dashboard(:title => 'Test Dashboard', client: client)

        tab = dashboard.create_tab(:title => 'Tab Title #1')
        tab.title = 'Test #42'

        item = tab.add_report_item(:report => report, :position_x => 10, :position_y => 20)
        item.position_x = 400
        item.position_y = 300
        dashboard.lock
        dashboard.save

        puts "Created project #{project.pid}"
        project
      end
    end
  end
end
