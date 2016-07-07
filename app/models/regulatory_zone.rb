
class RegulatoryZone  < Ekylibre::Record::Base


  def self.unify_shapes
    ActiveRecord::Base.connection.execute "SELECT ST_Union(VZ.shape) FROM regulatory_zones as VZ
                                          where VZ.type = 'VulnerableZone'"
  end

  def self.build_non_spreadable_zone

    regulatory_zone_types = RegulatoryZone.pluck(:type)

    #create a hash with
    # key = type of regulary zone
    # value = object Regulatory zone for this type
    regulatory_zones = {}
    regulatory_zone_types.each do |type|
      regulatory_zones[type] = (Object.const_get type).all
    end

=begin
    ### Build the feature_collection
    #build geometry_object for vulnerable_zones
    shapes = []
    regulatory_zones.each_value do |regulatory_zone|
      regulatory_zone.map { |zone| shapes << zone.shape}
    end

    #mutlipolygone to describe regulatory zone

    feature_collections = {}
    regulatory_zone.each_with_index { |regulatory_zone, type |
      features[type] = objects_to_feature(regulatory_zone)
    }
 ##TO DO add the properties
    regulatory_zones_feature_collection = features_to_feature_collection(features.values)
=end

    regulatory_zones_shape = RegulatoryZone.unify_shapes


    #res = {feature_collection: regulatory_zones_feature_collection, union_shape: regulatory_zones_shape}
    byebug

  end

end