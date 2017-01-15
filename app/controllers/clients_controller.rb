class ClientsController < ApplicationController
  unloadable
  include TypicalEntity::Controller
  # => find_model_objects
  # => build_new_model_object_from_params
  # => actions (index, show, edit, ...)
  # => link_to_object
  # => default_object(s)_(path|url)
  
  before_action :find_optional_project
  before_action :find_model_object, only: [:show, :edit, :update]
  before_action :find_model_objects, only: [:index, :bulk_edit, :bulk_update, :destroy]
  before_action :build_new_model_object_from_params, only: [:new, :create]
  before_action :update_model_object_from_params, only: [:edit, :update]
  
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  #???
  
  helper :journals
  helper :projects
  helper :custom_fields
  helper :watchers
  
  model_object Client
  
  def link_to_object(object = @object)
    view_context.link_to("##{object.id}", default_object_path(object), title: object.name)
  end
  
  def default_objects_path
    project_clients_path(@project)
  end
  
  def default_object_path(object)
    project_client_path(@project, object)
  end
  
  def default_object_url(object)
    project_client_url(@project, object)
  end
end
