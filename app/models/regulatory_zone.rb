
class RegulatoryZone  < Ekylibre::Record::Base

  def self.build_non_spreadable_zone(manure_management_plan,options={})
    #Build the intersection between non spreadable zones and the zones from manure_management_plan
    # return a hash {shape : <regulatory_zone>,
    #                 info : {"areas" => {<id> => <spreadable_area> (int)(square meters) }}
    #
    # options are used to define the buffer size in square meters
    options[:watercourse_buffer] ||= 25
    options[:bodyofwater_buffer] ||= 25
    options[:vulnerablezone_buffer] ||= 0
    options[:default] ||= 0
    info = {:areas => {}}

=begin
     Compute the union of each Regulatory zone that intersects with an activity_production support_shape.
     The Regulatory zones receive a buffer of n metters depending of there type. you can specify the buffer size with
     the option hash
=end
    non_spreadable_zone_shape = (ActiveRecord::Base.connection.execute "SELECT ST_AsEWKT(ST_Union(ST_Intersection(

                                                                  ST_Buffer(RZ.shape::geography, CASE RZ.type
                                                                                            WHEN 'Watercourse' THEN #{options[:watercourse_buffer]}
                                                                                            WHEN 'BodyOfWater' THEN #{options[:bodyofwater_buffer]}
                                                                                            WHEN 'VulnerableZone' THEN #{options[:vulnerablezone_buffer]}
                                                                                            ELSE #{ options[:default]}
                                                                                        END)::geometry, AP.support_shape)))
                                                  FROM regulatory_zones as RZ
                                                  JOIN activity_productions as AP on RZ.shape && AP.support_shape
                                                   WHERE AP.campaign_id = 4
                                                  ;", manure_management_plan.campaign.id).first.values.first

    non_spreadable_charta = Charta.new_geometry(non_spreadable_zone_shape)

    manure_management_plan.zones.each do |zone|
      zone_charta = Charta.new_geometry(zone.shape)
      info[:areas][zone.id] =  zone_charta.other(non_spreadable_charta).area
    end
    return { shape: res.first.values.first,info: info }
  end
end