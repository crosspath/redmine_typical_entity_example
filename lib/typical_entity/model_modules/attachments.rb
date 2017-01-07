module TypicalEntity::Model::AttachmentsModule
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
