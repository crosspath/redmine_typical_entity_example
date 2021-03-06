ActionDispatch::Callbacks.to_prepare do
  Redmine::Notifiable.class_eval do
    class << self
      # Replace standard behaviour to API-like.
      alias :old_all :all
      def all
        @notifications
      end
      
      def add(event)
        @notifications << Redmine::Notifiable.new(event)
      end
      
      def add_standard_notifications
        @notifications = old_all
      end
    end
    
    add_standard_notifications
  end
end
