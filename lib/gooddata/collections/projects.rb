module GoodData::Collections
  class Projects < Array
    def create(attributes)
      GoodData.logger.info "Creating project #{attributes[:name]}"

      json = {
        'meta' => {
          'title' => attributes[:name],
          'summary' => attributes[:summary]
        },
        'content' => {
          # 'state' => 'ENABLED',
          'guidedNavigation' => 1
        }
      }

      json['meta']['projectTemplate'] = attributes[:template] if attributes.has_key? :template

      self << GoodData::Project.create(json)
      last
    end
  end
end
