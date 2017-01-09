class ClientsController < ApplicationController
  unloadable
  include TypicalEntity::Controller
  # => find_model_objects
  # => build_new_model_object_from_params
  # => actions (index, show, edit, ...)
  # => link_to_object
  
  before_action :find_optional_project
  before_action :find_model_object, only: [:show, :edit, :update]
  before_action :find_model_objects, only: [:index, :bulk_edit, :bulk_update, :destroy]
  before_action :build_new_model_object_from_params, only: [:new, :create]
  
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
end
