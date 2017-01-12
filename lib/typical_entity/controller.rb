module TypicalEntity
  module Controller
    def self.included(base)
      base.class_eval do
        helper :queries
        include QueriesHelper
        helper :sort
        include SortHelper
      end
    end
    
    # before_action:
    
    def find_model_objects
      model = self.class.model_object
      @objects = if model
        pkey = model.primary_key
        model.where(pkey => params[pkey])
      else
        nil
      end
      if @objects.exist?
        self.instance_variable_set('@' + controller_name, @objects)
      else
        render_404
      end
    end
    
    def build_new_model_object_from_params
    end
    
    # actions:
    
    # @query.default_sort_criteria => [['id', 'desc']]
    # @query.sort_criteria => @sort_criteria ||= default_sort_criteria
    def index
      # Method from QueriesHelper
      retrieve_query(query_class)
      # Methods from SortHelper
      sort_init(@query.sort_criteria)
      sort_update(@query.sortable_columns)
      @query.sort_criteria = sort_criteria.to_a

      if @query.valid?
        prepare_query_index

        @object_count = @query.object_count
        @object_pages = Paginator.new @object_count, @limit, params['page']
        @offset ||= @object_pages.offset
        @objects = @query.objects(params_for_query_objects)
        @object_count_by_group = @query.object_count_by_group

        respond_to { |format| render_index(format) }
      else
        respond_to { |format| render_error_index(format) }
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end
    
    def show
      prepare_show
      respond_to { |format| render_show(format) }
    end
    
    def new
      respond_to { |format| render_new(format) }
    end
    
    def create
      return unless request.post?
      prepare_object_create
      
      if @object.save
        respond_to { |format| render_create(format) }
      else
        respond_to { |format| render_error_create(format) }
      end
    end
    
    def edit
      respond_to { |format| render_edit(format) }
    end
    
    def update
      return unless request.post?
      prepare_object_update
      
      if @object.save
        respond_to { |format| render_update(format) }
      else
        respond_to { |format| render_error_update(format) }
      end
    end
    
    # helper methods:
    
    private
    
    def query_class
      @query_class ||= begin
        raise if self.class.model_object.blank?
        (self.class.model_object + 'Query').constantize
      rescue => e
        raise StandardError, "Can't find query class for #{controller_name}"
      end
    end
    
    # Redefine it to append options:
    # def params_for_query_objects
    #   super.merge(include: [:user])
    # end
    def params_for_query_objects
      {order: sort_clause, offset: @offset, limit: @limit}
    end
    
    def prepare_query_index
      case params[:format]
          when 'csv', 'pdf'
            @limit = Setting.issues_export_limit.to_i
            if params[:columns] == 'all'
              @query.column_names = @query.available_inline_columns.map(&:name)
            end
          when 'atom'
            @limit = Setting.feeds_limit.to_i
          when 'xml', 'json'
            @offset, @limit = api_offset_and_limit
            @query.column_names = %w(name)
          else
            @limit = per_page_option
        end
    end
    
    def render_index(format)
      format.html { render action: 'index', layout: !request.xhr? }
      
      format.api
      
      format.atom do
        raise if self.class.model_object.blank?
        model_object = self.class.model_object
        
        label = l("label_#{model_object.name.underscore}_plural")
        render_feed(@objects, title: "#{@project || Setting.app_title}: #{label}")
      end
      
      format.csv  do
        row_data = query_to_csv(@objects, @query, params[:csv])
        send_data(row_data, type: 'text/csv; header=present', filename: export_file_name('csv'))
      end
      
      format.pdf  do
        send_file_headers! type: 'application/pdf', filename: export_file_name('pdf')
      end
    end
    
    def render_error_index(format)
      format.html { render action: 'index', layout: !request.xhr? }
      format.any(:atom, :csv, :pdf) { head 422 }
      format.api { render_validation_errors(@query) }
    end
    
    # Override it if you want to add statements to `show` action before render.
    def prepare_show
      prepare_journals_show if @object.respond_to? :journals
    end
    
    def prepare_journals_show
      journals = @object.journals
      user = User.current
      
      @journals = journals.preload(:details).preload(user: :email_address).reorder(:created_on, :id).to_a
      @journals.each_with_index { |j, i| j.indice = i + 1 }
      
      unless @object.respond_to?(:project) && user.allowed_to?(:view_private_notes, @object.project)
        @journals.reject!(&:private_notes?)
      end
      
      Journal.preload_journals_details_custom_fields(@journals)
      @journals.select! { |journal| journal.notes? || journal.visible_details.any? }
      @journals.reverse! if user.wants_comments_in_reverse_order?
    end
    
    def render_show(format)
      format.html do
        retrieve_previous_and_next_issue_ids
        render action: 'show'
      end
      
      format.api
      
      format.atom do
        render template: 'journals/index', layout: false, content_type: 'application/atom+xml'
      end
      
      format.pdf do
        send_file_headers! type: 'application/pdf', filename: export_file_name('pdf')
      end
    end
    
    def export_file_name(ext)
      model_object = self.class.model_object
      if instance_variable_defined?(:@object) && @object # maybe, `instance_variable_defined?` is not needed
        file_name_parts = [model_object.name, @object[model_object.primary_key]]
        if @object.respond_to?(:project) && @object.project
          file_name_parts.unshift(@object.project.identifier)
        end
        file_name_parts.join('-') + ".#{ext}"
      else
        model_object.tableize + ".#{ext}"
      end
    end
    
    def render_new(format)
      format.html { render layout: !request.xhr? }
      format.js
    end
    
    def link_to_object(object = @object)
      pkey = self.class.model_object.primary_key
      view_context.link_to("##{object[pkey]}", default_object_path(object)) # third arg: {title: object.name}
    end
    
    def prepare_object_create
      object_save_attachments if @object.respond_to? :save_attachments
    end
    
    def object_save_attachments
      obj_key = self.class.model_object.name.underscore
      attachments = params[:attachments] || (params[obj_key] && params[obj_key][:uploads])
      @object.save_attachments(attachments)
    end
    
    def render_create(format)
      format.html do
        render_attachment_warning_if_needed(@object) if @object.respond_to? :attachments
        flash[:notice] = l(:notice_successful_create, id: link_to_object)
        redirect_back_or_default default_object_path
      end
      
      format.js
      
      format.api { render action: 'show', status: :created, location: default_object_url }
    end
    
    def render_error_create(format)
      format.html { render action: 'new' }
      format.js { render action: 'new' }
      format.api { render_validation_errors(@object) }
    end
    
    def render_edit(format)
      format.html
      format.js
    end
    
    def prepare_object_update
      object_save_attachments if @object.respond_to? :save_attachments
    end
    
    def render_update(format)
      if @object.respond_to?(:current_journal) && !@object.current_journal.new_record?
        flash[:notice] = l(:notice_successful_update)
      end
      
      format.html do
        render_attachment_warning_if_needed(@object) if @object.respond_to? :attachments
        flash[:notice] = l(:notice_successful_create, id: link_to_object)
        redirect_back_or_default default_object_path
      end
      
      format.js
      
      format.api { render_api_ok }
    end
    
    def render_error_update(format)
      format.html { render action: 'edit' }
      format.js { render action: 'edit' }
      format.api { render_validation_errors(@object) }
    end
  end
end
