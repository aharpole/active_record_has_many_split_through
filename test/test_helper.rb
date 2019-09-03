$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_record_has_many_split_through"
require "byebug"

require "minitest/autorun"

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.verbose = false

class A < ActiveRecord::Base
  self.abstract_class = true
end

class B < ActiveRecord:: Base
  self.abstract_class = true
  establish_connection(adapter: 'sqlite3', database: ':memory:')
end

class C < ActiveRecord:: Base
  self.abstract_class = true
  establish_connection(adapter: 'sqlite3', database: ':memory:')
end

class D < ActiveRecord:: Base
  self.abstract_class = true
  establish_connection(adapter: 'sqlite3', database: ':memory:')
end

class ShippingCompany < A
  has_many :offices # A
  has_many :employees, through: :offices # A → A

  has_many :docks # B
  has_many :ships, through: :docks, split: true, batch_size: 10 # B → C
  has_many :whistles, through: :ships, split: true # C → A
end

class Office < A
  belongs_to :shipping_company # A
  has_many :employees # A
end

class Employee < A
  belongs_to :office # A
end

class Whistle < A
  belongs_to :ship # C
end

class Dock < B
  belongs_to :shipping_company # A
  has_many :ships # C
end

class Ship < C
  belongs_to :dock # B
  has_many :whistles # A
  has_many :chairs # C
  has_many :chair_legs, through: :chairs
end

require_relative "schema"
