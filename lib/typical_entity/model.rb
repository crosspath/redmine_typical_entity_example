module TypicalEntity
  module Model
    class << self
      def typical_features(*args)
        class_eval do
          include ::Redmine::I18n
          include ::Redmine::SafeAttributes
          
          def css_classes(user = User.current)
            self.class.name.underscore
          end
          
          args.each do |arg|
            case arg
            when :attachments then include(AttachmentsModule)
            when :journals then include(JournalsModule)
            when :private_journals then include(PrivateJournalsModule)
            when :watchers then include(WatchersModule)
            else
              raise StandardError, "Unsupported feature: #{arg} (#{self.name})"
            end
          end
        end
      end # typical_features
      
      def notify_on(*args)
        class_eval do
          if args.include? :create
            after_create :send_notification
          end
          
          def notified_users
            # array of Users
          end
          
          def recipients
            notified_users.map(&:mail)
          end
          
          private
          
          def send_notification
            # Example:
            # if notify? && Setting.notified_events.include?('issue_added')
            #   Mailer.deliver_issue_add(self)
            # end
          end
        end
      end # notify_on
    end
    
    module AttachmentsModule
      def self.included(base)
        base.class_eval do
          acts_as_attachable after_add: :attachment_added, after_remove: :attachment_removed
          
          attr_accessor :deleted_attachment_ids
          
          safe_attributes 'deleted_attachment_ids', if: ->(obj, user) { obj.attachments_deletable?(user) }
          
          def deleted_attachment_ids
            Array(@deleted_attachment_ids).map(&:to_i)
          end
          
          def delete_selected_attachments
            if deleted_attachment_ids.present?
              objects = attachments.where(id: deleted_attachment_ids.map(&:to_i))
              attachments.delete(objects)
            end
          end

          def attachment_added(attachment)
            attachment_action(attachment) do
              current_journal.journalize_attachment(attachment, :added)
            end
          end

          def attachment_removed(attachment)
            attachment_action(attachment) do
              current_journal.journalize_attachment(attachment, :removed)
              current_journal.save
            end
          end
          
          private
          
          def attachment_action(attachment, &block)
            if respond_to?(:current_journal) && current_journal && !attachment.new_record?
              block.call
            end
          end
        end
      end
    end
    
    module JournalsModule
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
            Issue.column_names - %w(id created_at updated_at)
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
    
    module PrivateJournalsModule
      def self.included(base)
        base.class_eval do
          safe_attributes 'private_notes',
            if: ->(obj, user) { obj.new_record? && obj.private_notes_addable?(user) }

          private
          
          def self.scope_visible_journals(collection)
            collection.where(["(#{Journal.table_name}.private_notes = ? OR (#{Project.allowed_to_condition(User.current, :view_private_notes)}))", false])
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
    
    module WatchersModule
      def self.included(base)
        base.class_eval do
          acts_as_watchable
          
          safe_attributes 'watcher_user_ids',
            :if => lambda {|issue, user| obj.new_record? && obj.watchable?(user) }
          
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
  end
end
