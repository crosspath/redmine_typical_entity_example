module TypicalEntity::Model::JournalsModule
  def self.included(base)
    base.class_eval do
      has_many :journals, as: :journalized, dependent: :destroy, inverse_of: :journalized
      has_many :visible_journals, -> { scope_visible_journals(self) }, class_name: 'Journal', as: :journalized
      
      attr_reader :current_journal
      delegate :notes, :notes=, :private_notes, :private_notes=, to: :current_journal, allow_nil: true
      
      safe_attributes 'notes', if: ->(obj, user) { obj.notes_addable?(user) }

      def init_journal(user, notes = "")
        @current_journal ||= Journal.new(journalized: self, user: user, notes: notes)
      end

      def current_journal
        @current_journal
      end
      
      def journalized_attribute_names
        self.class.column_names - %w(id created_at updated_at)
      end
      
      def last_journal_id
        new_record? ? nil : journals.maximum(:id)
      end
      
      def journals_after(journal_id)
        journals_table = Journal.table_name
        scope = journals.reorder("#{journals_table}.id ASC")
        scope = scope.where("#{journals_table}.id > ?", journal_id.to_i) if journal_id.present?
        scope
      end

      private
      
      def self.scope_visible_journals(collection)
        collection
      end
      
      def create_journal
        current_journal.save if current_journal
      end
        
      def notes_addable?(user = User.current)
        if respond_to?(:project)
          user.allowed_to?(:add_issue_notes, project)
        else
          raise "Add `project` to class instance (belongs_to :project) or redefine this method. " +
              "Also, it'll be good to use custom permission, not `add_issue_notes`."
        end
      end
    end
  end
end
