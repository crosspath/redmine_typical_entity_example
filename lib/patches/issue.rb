ActionDispatch::Callbacks.to_prepare do
    class Issue
        PLUGIN_SUPPLY_CUSTOM_FIELDS = [
            {name: 'Клиент', field_format: 'client', editable: true, visible: true, multiple: false},
            {name: 'Товары', field_format: 'product', editable: true, visible: true, multiple: true},
            {name: 'Ожидаемая дата доставки', field_format: 'date', editable: true, visible: true, multiple: false},
            {name: 'Адрес доставки', field_format: 'string', editable: true, visible: true, multiple: false},
            {name: 'Сумма', field_format: 'float', editable: true, visible: true, multiple: false}
        ]
    end
end
