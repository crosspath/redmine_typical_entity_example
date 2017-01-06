module PluginSupply
  class Clients < ActiveRecord::Base
    unloadable
    include TypicalEntity::Model
    typical_features :journals, :watchers
  end
end
