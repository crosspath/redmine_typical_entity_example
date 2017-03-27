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
    
    def object_count
      default_scope_object.count
    #rescue ::ActiveRecord::StatementInvalid => e
    #  raise ::Query::StatementInvalid.new(e.message)
    end
    
    def project_statement
      if self.class.queried_class.reflections.key?('project')
        super
      else
        nil
      end
    end
    
    # example: self.class.queried_class.visible
    def default_scope_object
      self.class.queried_class.where(statement)
    end

    # Returns the object count by group or nil if query is not grouped
    def object_count_by_group
      return nil unless grouped?
      
      r = begin
          # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
          default_scope_object.
            joins(joins_for_order_statement(group_by_statement)).
            group(group_by_statement).
            count
        rescue ActiveRecord::RecordNotFound
          {nil => object_count}
        end
      
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.reduce({}) { |h, k| h[c.custom_field.cast_value(k)] = r[k]; h }
      end

      r
    #rescue ::ActiveRecord::StatementInvalid => e
    #  raise ::Query::StatementInvalid.new(e.message)
    end

    # Returns the objects
    # Valid options are :order, :offset, :limit, :include, :conditions
    def objects(options={})
      order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

      scope = default_scope_object.
          includes(((@joins_values || []) + (options[:include] || [])).uniq).
          where(options[:conditions]).
          order(order_option).
          joins(joins_for_order_statement(order_option.join(','))).
          limit(options[:limit]).
          offset(options[:offset]).
          preload(:custom_values)

      scope.all
    #rescue ::ActiveRecord::StatementInvalid => e
    #  raise ::Query::StatementInvalid.new(e.message)
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
