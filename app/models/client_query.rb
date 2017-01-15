class ClientQuery < Query
  include TypicalEntity::Query
  # => default_columns - id, created_at, updated_at
  
  self.queried_class = Client
  self.view_permission = :view_clients
  
  self.available_columns = default_columns
end
