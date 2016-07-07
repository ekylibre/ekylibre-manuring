
class AdministrativeArea  < Ekylibre::Record::Base

  scope :contains, lambda { |shape|
    where("ST_Contains(shape,#{Charta.new_geometry(shape).geom})")
  }

end