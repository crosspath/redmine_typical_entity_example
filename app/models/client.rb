class Client < ActiveRecord::Base
  unloadable
  include TypicalEntity::Model
  
  typical_features :journals, :watchers
  # Call `notified_users` after updating Client.
  notify_on update: :notified_users
  
  def notified_users
    # send emails to assignees of orders of this Client
    cf = IssueCustomField.find_by(name: 'Client', field_format: 'client')
    cv = cf.custom_values.where(value: self.id.to_s, customized_type: 'Issue')
    issues = cv.pluck(:customized_id)
    assignees = Issue.where(id: issues).pluck(:assigned_to_id)
    principals = Principal.where(id: assignees)
    users = principals.flat_map { |pr| pr.is_a?(Group) ? pr.users : pr }
    filter_active_notified_users(users)
  end
end
