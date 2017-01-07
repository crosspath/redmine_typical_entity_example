module TypicalEntity
  module Model
    class << self
      # Usage:
      # class MyModel < ActiveRecord::Base
      #   include TypicalEntity::Model
      #   typical_features :attachments, :watchers
      # end
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
      
      # Usage:
      # class MyModel < ActiveRecord::Base
      #   include TypicalEntity::Model
      #   notify_on create: -> { User.where(admin: true) }, update: :notified_users
      #   def notified_users
      #     filter_active_notified_users([author] + watchers)
      #   end
      # end
      def notify_on(events = {})
        class_eval do
          events.each do |event, fn_notified_users|
            case event
            when :create
              method_name = define_notification_method('added', fn_notified_users)
              after_create method_name
            when :update
              method_name = define_notification_method('updated', fn_notified_users)
              after_update method_name
            else
              raise StandardError, "Unsupported notification event: #{event} (#{self.name})"
            end
          end # events.each
          
          def filter_active_notified_users(notified)
            notified.uniq.select { |u| u.active? && u.notify_about?(self) }
          end
          # TODO: Currently`notify_about?` cares about Issue and News only 
          # or it allows all / denies all notifications.
          
          private
          
          # Accepts method name for `notified_users` list or block/Proc that returns `notified_users` list.
          def define_notification_method(event, fn_notified_users)
            notified_event = "#{self.class.name.underscore}_#{event}"
            Redmine::Notifiable.add(notified_event)
            
            define_method "send_notification_#{event}" do
              users = fn_notified_users.respond_to?(:call) ? fn_notified_users.call : send(fn_notified_users)
              if notify? && Setting.notified_events.include?(notified_event)
                Mailer.send("deliver_#{notified_event}", self, users)
              end
            end
          end
        end
      end # notify_on
    end
  end # module Model
end

Dir[File.join(File.dirname(__FILE__), 'model_modules', '*.rb')].each { |x| require x }
