module TypicalEntity::Model::PrivateJournalsModule
  def self.included(base)
    base.class_eval do
      safe_attributes 'private_notes',
        if: ->(obj, user) { obj.new_record? && obj.private_notes_addable?(user) }

      private
      
      def self.scope_visible_journals(collection)
        project_condition = Project.allowed_to_condition(User.current, :view_private_notes)
        collection.where(["(#{Journal.table_name}.private_notes = ? OR (#{project_condition}))", false])
      end
      
      def private_notes_addable?(user = User.current)
        if respond_to?(:project)
          user.allowed_to?(:set_notes_private, project)
        else
          raise "Add `project` to class instance (belongs_to :project) or redefine this method."
        end
      end
    end
  end
end
