module TypicalEntity
  module Query
    def initialize(attrs = nil, *args)
      super(attrs)
      self.filters ||= default_filters
    end
    
    # used on initialization
    def default_filters
      {}
    end
    
    # Usage:
    # def initialize_available_filters
    #   super do
    #     add_available_filter "column", type: :string
    #   end
    # end
    # todo: support custom fields  which are not for all projects
    def initialize_available_filters(&block)
      add_available_filter "created_at", type: :date_past
      add_available_filter "updated_at", type: :date_past
      
      block.call if block_given?
      
      custom_field_class = "#{self.class.queried_class.name}CustomField"
      begin
        custom_fields = custom_field_class.constantize.where(is_for_all: true)
        add_custom_fields_filters(custom_fields)
      rescue NameError => e
        # do nothing
      end
      
      add_associations_custom_fields_filters(*self.class.queried_class.reflections.keys)
    end
    
    def self.included(base)
      base.class_eval do
        class << self
          def default_columns
            table_name = self.queried_class.table_name
            cols = []
            cols << QueryColumn.new(:id, sortable: "#{table_name}.id", default_order: 'desc', caption: '#', frozen: true)
            cols << QueryColumn.new(:created_on, sortable: "#{table_name}.created_on", default_order: 'desc')
            cols << QueryColumn.new(:updated_on, sortable: "#{table_name}.updated_on", default_order: 'desc')
            cols
          end
        end # class << self
      end
    end # self.included
  end
end
