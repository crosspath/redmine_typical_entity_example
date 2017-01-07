class IssueCustomFields < ActiveRecord::Migration
  def up
      Issue::PLUGIN_SUPPLY_CUSTOM_FIELDS.each do |cf|
          IssueCustomField.create!(cf)
      end
  end
  
  def down
      Issue::PLUGIN_SUPPLY_CUSTOM_FIELDS.each do |cf|
          IssueCustomField.where(name: cf[:name], field_format: cf[:field_format]).delete_all
      end
  end
end
