module Redmine::FieldFormat
    RecordList.customized_class_names << 'Client'
    
    class ClientFormat < RecordList
        add 'client'
        self.form_partial = 'custom_fields/formats/client'

        def possible_values_options(custom_field, object = nil)
            possible_values_records(custom_field, object).map { |u| [u.name, u.id.to_s] }
        end

        def possible_values_records(custom_field, object = nil)
            Client.order('name')
        end

        def value_from_keyword(custom_field, keyword, object)
            clients = possible_values_records(custom_field, object)
            value = clients.find_by('lower(name) like lower(?)', keyword)
            value ? value.id : nil
        end
    end
end
