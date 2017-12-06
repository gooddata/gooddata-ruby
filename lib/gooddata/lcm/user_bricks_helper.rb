module GoodData
  module LCM2
    # Contains code shared by Users Brick and User Filters Brick
    class UserBricksHelper
      class << self
        def resolve_client_id(domain, project, data_product)
          md = project.metadata
          goodot_id = md['GOODOT_CUSTOM_PROJECT_ID'].to_s

          client = domain.clients(:all, data_product).find do |c|
            c.project_uri == project.uri
          end
          if goodot_id.empty? && client.nil?
            fail "Project \"#{project.pid}\" metadata does not contain key " \
                 "GOODOT_CUSTOM_PROJECT_ID neither is it mapped to a " \
                 "client_id in LCM metadata. We are unable to get the " \
                 "values for user filters."
          end

          unless goodot_id.empty? || client.nil? || (goodot_id == client.id)
            fail "GOODOT_CUSTOM_PROJECT_ID metadata key is provided for " \
                 "project \"#{project.pid}\" but doesn't match client id " \
                 "assigned to the project in LCM metadata. " \
                 "Please resolve the conflict."
          end

          goodot_id.empty? ? client.id : goodot_id
        end
      end
    end
  end
end
