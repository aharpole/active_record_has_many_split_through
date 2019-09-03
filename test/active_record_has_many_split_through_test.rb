require "test_helper"

class ActiveRecordHasManySplitThroughTest < Minitest::Test
  def setup
    create_fixtures
  end

  def teardown
    remove_everything
  end

  def test_that_it_has_a_version_number
    refute_nil ::ActiveRecordHasManySplitThrough::VERSION
  end

  def test_counting_through_same_database
    assert_equal 2, @company.employees.count
  end

  def test_counting_through_other_database
    assert_equal 1, @company.ships.count
  end

  def test_fetching_through_same_database
    assert_equal @employee.id, @company.employees.first.id
  end

  def test_fetching_through_other_database
    assert_equal @ship.id, @company.ships.first.id
  end

  def test_appending_through_same_database
    assert_difference(->() { @company.employees.reload.size }) do
      @office.employees.create(name: "howard")
    end
  end

  def test_appending_through_other_database
    assert_difference(->() { @company.ships.reload.size }) do
      @dock.ships.create(name: "howard")
    end
  end

  def test_to_a_through_same_database
    assert_equal [@employee, @employee2], @company.employees.sort.to_a
  end

  def test_to_a_through_other_database
    assert_equal [@ship], @company.ships.to_a
  end

  def test_empty_through_other_database
    assert_equal [], @company3.whistles
  end

  def test_pluck_through_same_database
    assert_equal Employee.all.pluck(:id), @company.employees.pluck(:id)
  end

  def test_pluck_through_other_database
    assert_equal Ship.where(dock: @dock).pluck(:id), @company.ships.pluck(:id)
  end

  # through a through

  def test_pluck_through_a_through
    assert_equal Whistle.where(ship: @ship).pluck(:id), @company.whistles.pluck(:id)
  end

  def test_count_through_a_through
    assert_equal 3, @company.whistles.count
  end

  # lots of stuff

  def test_lots_of_records
    100.times do |n|
      dock = @company4.docks.create!(name: "Dock #{n}")
      100.times do |j|
        dock.ships.create!(name: "Ship #{j}")
      end
    end

    assert_equal 10_000, @company4.ships.count
  end

  private

  def create_fixtures
    @company = ShippingCompany.create!(name: "GitHub")
    @company2 = ShippingCompany.create!(name: "Microsoft")
    @company3 = ShippingCompany.create!(name: "Wunderlist")
    @company4 = ShippingCompany.create!(name: "Big lots!")

    @office = @company.offices.create!(name: "Back Office")
    @office2 = @company.offices.create!(name: "Front Office")
    @office3 = @company2.offices.create!(name: "Front Office")

    @employee = @office.employees.create!(name: "Alice")
    @employee2 = @office2.employees.create!(name: "Not Alice")

    @dock = @company.docks.create!(name: "Primary")
    @dock2 = @company2.docks.create!(name: "Primary")

    @ship = @dock.ships.create!(name: "Alton")
    @ship2 = @dock2.ships.create!(name: "Not Alton")

    @ship.whistles.create!()
    @ship.whistles.create!()
    @ship.whistles.create!()

    @ship2.whistles.create!()
    @ship2.whistles.create!()
  end

  def remove_everything
    ShippingCompany.connection.execute("delete from shipping_companies;")
    Office.connection.execute("delete from offices;")
    Employee.connection.execute("delete from employees;")
    Dock.connection.execute("delete from docks;")
    Ship.connection.execute("delete from ships;")
    Whistle.connection.execute("delete from whistles;")
  end

  def assert_difference(record_count)
    before = record_count.call
    yield
    assert_equal before + 1, record_count.call
  end
end
