ActionDispatch::Callbacks.to_prepare do
    module PluginSupply::IssuePatch
        PLUGIN_SUPPLY_CUSTOM_FIELDS = [
            {name: 'Client', field_format: 'client', editable: true, visible: true, multiple: false},
            {name: 'Products', field_format: 'product', editable: true, visible: true, multiple: true},
            {name: 'Expected date of delivery', field_format: 'date', editable: true, visible: true, multiple: false},
            {name: 'Delivery address', field_format: 'string', editable: true, visible: true, multiple: false},
            {name: 'Sum', field_format: 'float', editable: true, visible: true, multiple: false}
        ]
    end
    Issue.include PluginSupply::IssuePatch
end
