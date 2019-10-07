$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_record_has_many_split_through"
require "minitest/autorun"
require "erb"

yaml_file = File.open('config/database.yml')
config_file = YAML.load(ERB.new(yaml_file.read).result)
ActiveRecord::Base.configurations = config_file
ActiveRecord::Base.establish_connection(:database_a)
ActiveRecord::Schema.verbose = false

#ActiveRecord::Base.logger = Logger.new($stderr)
NO_SPLIT = ENV['NO_SPLIT']

class A < ActiveRecord::Base
  self.abstract_class = true
end

class B < ActiveRecord:: Base
  self.abstract_class = true

  unless NO_SPLIT
    establish_connection(:database_b)
  end
end

class C < ActiveRecord:: Base
  self.abstract_class = true

  unless NO_SPLIT
    establish_connection(:database_c)
  end
end

class D < ActiveRecord:: Base
  self.abstract_class = true

  unless NO_SPLIT
    establish_connection(:database_d)
  end
end

class ShippingCompany < A
  has_many :offices # A
  has_many :employees, through: :offices # A → A

  has_many :docks # B
  has_many :ships, through: :docks, split: !NO_SPLIT  # B → C
  has_many :whistles, through: :ships, split: !NO_SPLIT  # C → A
  has_many :containers, through: :docks, split: !NO_SPLIT  # B → D

  has_many :broken_whistles,
     -> { where(broken: true).order(id: :desc) },
     through: :ships,
     source: :whistles,
     split: !NO_SPLIT # C → A
end

class Office < A
  belongs_to :shipping_company # A
  has_many :employees # A
end

class Employee < A
  belongs_to :office # A
  has_many :favorites

  has_many :favorite_ships,
    through: :favorites,
    source: :favoritable,
    source_type: "Ship",
    split: !NO_SPLIT

  has_many :favorite_docks,
    through: :favorites,
    source: :favoritable,
    source_type: "Dock",
    split: !NO_SPLIT

  has_one :profile
  has_many :profile_pins, -> { ordered_by_position }, through: :profile
  has_many :pinned_ships,
    through: :profile_pins,
    source: :pinned_item,
    source_type: "Ship",
    split: !NO_SPLIT
end

class Whistle < A
  belongs_to :ship # C
end

class Profile < A
  belongs_to :employee # C
  has_many :profile_pins
end

class Dock < B
  belongs_to :shipping_company # A
  has_many :ships # C
  has_many :containers # D
  has_many :favorites, as: :favoritable #B
end

class Favorite < B
  belongs_to :employee
  belongs_to :favoritable, polymorphic: true
end

class ProfilePin < B
  scope :ordered_by_position, -> { order("profile_pins.position ASC") }

  belongs_to :profile
  has_one :employee, through: :profile
  belongs_to :pinned_item, polymorphic: true
end

class Ship < C
  belongs_to :dock # B
  has_many :whistles # A
  has_many :favorites, as: :favoritable #B
  has_many :profile_pins, as: :pinned_item
  has_many :containers,
    foreign_key: "container_registration_number_id",
    through: :dock,
    split: !NO_SPLIT # B → D
end

class Container < D
  self.primary_key = "registration_number"
  belongs_to :dock # B
end

begin
  require_relative "schema"
rescue ActiveRecord::NoDatabaseError
  puts "===================================================================================="
  puts "\n"
  puts "The database does not exist."
  puts "Please run `bin/rake db:create` to create the database."
  puts "\n"
  puts "===================================================================================="
  exit!
end
