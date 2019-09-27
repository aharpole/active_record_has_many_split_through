# frozen_string_literal: true

A.connection.create_table :shipping_companies, force: true do |t|
  t.string :name
end

A.connection.create_table :offices, force: true do |t|
  t.string :name
  t.references :shipping_company
end

A.connection.create_table :employees, force: true do |t|
  t.string :name
  t.references :office
end

A.connection.create_table :whistles, force: true do |t|
  t.boolean :broken, default: false
  t.references :ship
end

A.connection.create_table :profiles, force: true do |t|
  t.references :employee
end

B.connection.create_table :docks, force: true do |t|
  t.string :name
  t.references :shipping_company
end

B.connection.create_table :favorites, force: true do |t|
  t.references :favoritable, polymorphic: true
  t.references :employee
end

B.connection.create_table :profile_pins, force: true do |t|
  t.references :pinned_item, polymorphic: true
  t.references :profile
  t.integer :position, null: false, default: 1
end

C.connection.create_table :ships, force: true do |t|
  t.string :name
  t.references :dock
end

D.connection.create_table :containers, id: false, force: true do |t|
  t.primary_key :registration_number
  t.references :dock
end
