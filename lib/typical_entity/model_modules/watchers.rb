module TypicalEntity::Model::WatchersModule
  def self.included(base)
    base.class_eval do
      acts_as_watchable
      
      safe_attributes 'watcher_user_ids', if: ->(obj, user) { obj.new_record? && obj.watchable?(user) }
      
      def watchable?(user = User.current)
        if respond_to?(:project)
          user.allowed_to?(:add_issue_watchers, project)
        else
          raise "Add `project` to class instance (belongs_to :project) or redefine this method. " +
              "Also, it'll be good to use custom permission, not `add_issue_watchers`."
        end
      end
    end
  end
end
