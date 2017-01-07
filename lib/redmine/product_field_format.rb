module Redmine::FieldFormat
    RecordList.customized_class_names << 'Product'
    
    class ProductFormat < RecordList
        add 'product'
        self.form_partial = 'custom_fields/formats/product'

        def possible_values_options(custom_field, object = nil)
            possible_values_records(custom_field, object).map { |u| [u.name, u.id.to_s] }
        end

        def possible_values_records(custom_field, object = nil)
            Product.order('name')
        end

        def value_from_keyword(custom_field, keyword, object)
            products = possible_values_records(custom_field, object)
            value = products.find_by('lower(name) like lower(?)', keyword)
            value ? value.id : nil
        end
    end
end
