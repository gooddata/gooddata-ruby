module Gooddata::Collections
  class Projects < Array
    def create(attributes)
      Gooddata.logger.info "Creating project #{attributes[:name]}"

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

      json['mata']['projectTemplate'] = attributes[:template] if attributes.has_key? :template

      self << Project.create(json)
      last
    end
  end
end
