require_relative '../brick_runner'

module Support
  class UserProvisioningHelper
    FILTER_DATA_COLUMN = 'value'

    class << self
      def uniq_label_with_value(project, value_count)
        blacklists = $generated_uniq_labels_with_value || {}
        blacklist = blacklists[project.pid] || []

        atts = project.attributes.to_a.sort_by(&:identifier)
        attribute = atts.shift while !attribute || attribute.date_attribute? || !attribute.primary_label || (blacklist.include? attribute)
        label = attribute.primary_label
        sorted_values = label.values.to_a.sort_by { |a| a[:value] }
        notempty = sorted_values.reject { |v| v[:value].empty? }
        values = notempty.slice(0, value_count)

        blacklists[project.pid] = blacklist.push attribute
        $generated_uniq_labels_with_value = blacklists
        [label, values.map { |v| v[:value] }]
      end

      def muf_data(opts = {})
        client = opts[:client]
        project = opts[:project]
        users = opts[:users]
        muf_complexity = opts[:muf_complexity] || 2

        label, values = uniq_label_with_value project, muf_complexity
        puts "Generated MUF for values #{values} of attribute #{label.title}"

        users.map do |u|
          values.map do |v|
            {
              login: u[:custom_login],
              client_id: client.client_id,
              value: v,
              label_id: label.identifier,
              project_id: project.pid
            }
          end
        end.flatten
      end

      def test_user_filters_brick(options = {})
        test_context = options[:test_context]
        mufs = options[:mufs]
        projects = options[:projects]

        BrickRunner.user_filters_brick context: test_context, template_path: '../params/user_filters_brick_e2e.json.erb'

        projects.each do |p|
          filters = p.user_filters.to_a
          label = p.attributes(mufs.first[:label_id])
          expected_filters_by_email = mufs.select { |m| m[:project_id] == p.pid }.group_by { |f| f[:login] }

          spec_env { expect(filters.length).to eq(expected_filters_by_email.length) }
          expected_filters_by_email.each do |email, expected_filters|
            # all emails are downcased during brick provisioning
            matching = filters.find { |f| f.related.email == email.downcase }
            expected_filters.each do |f|
              value = label.find_value_uri f[:value]
              spec_env { expect(matching.expression).to include value }
            end
          end
        end
      end

      def test_users_brick(options = {})
        test_context = options[:test_context]
        projects = options[:projects]
        user_data = options[:user_data]

        BrickRunner.users_brick context: test_context, template_path: '../params/users_brick_e2e.json.erb'

        projects.each do |p|
          users = p.users.to_a
          spec_env { expect(users.length).to eq((user_data.count / projects.count) + 1) } # the user who created the project is also a member
          # TODO: check the data is the same
        end
      end

      def label_config(mufs)
        [{ value: FILTER_DATA_COLUMN, label: mufs.first[:label_id] }]
      end
    end
  end
end
