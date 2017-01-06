module PluginSupply
end

Dir[File.join(File.dirname(__FILE__), 'typical_entity', '*.rb')].each { |x| require x }
