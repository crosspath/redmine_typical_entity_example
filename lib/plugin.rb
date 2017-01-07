module PluginSupply
    class << self
        def require_all_in(dir)
            @dir ||= File.dirname(__FILE__)
            Dir[File.join(@dir, dir, '*.rb')].each { |x| require x }
        end
    end
end

PluginSupply.require_all_in 'typical_entity'
PluginSupply.require_all_in 'patches'
PluginSupply.require_all_in 'redmine'
