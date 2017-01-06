Redmine::Plugin.register :plugin_supply do
  name 'Plugin Supply'
  author 'Author name'
  description 'Plugin for Redmine, based on `redmine_typical_entity` plugin.'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  # Список клиентов и продуктов является общим для всех проектов в системе.
  # Чтобы добавить к задачам поля для связывания задач с клиентами и продуктами,
  # нужно включить модуль `plugin_supply` в проекте.
  project_module :plugin_supply do
    permission :view_clients, {clients: [:index, :show]}
    permission :edit_clients, {clients: [:edit, :new, :create, :update, :destroy]}
    
    permission :view_products, {products: [:index, :show]}
    permission :edit_products, {products: [:edit, :new, :create, :update, :destroy]}
  end
  
  menu :project_menu, :clients, {controller: :clients, action: :index},
          param: :project_id,
          caption: :label_clients_plural,
          permission: :view_clients
  
  menu :project_menu, :products, {controller: :products, action: :index},
          param: :project_id,
          caption: :label_products_plural,
          permission: :view_products
end

require_relative 'lib/plugin.rb'
