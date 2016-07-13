
class RegulatoryZone  < Ekylibre::Record::Base

  def self.unified_shape
    ActiveRecord::Base.connection.execute("SELECT ST_Union(RZ.shape)
                                            FROM regulatory_zones RZ
                                            Where type = '#{self.name}' ;").first.values.first
  end

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
    ActiveRecord::Base.logger = nil
    non_spreadable_zone_shape = (ActiveRecord::Base.connection.execute "SELECT ST_Union(ST_Intersection(

                                                                  ST_Buffer(RZ.shape::geography, CASE RZ.type
                                                                                            WHEN 'Watercourse' THEN #{options[:watercourse_buffer]}
                                                                                            WHEN 'BodyOfWater' THEN #{options[:bodyofwater_buffer]}
                                                                                            ELSE #{ options[:default]}
                                                                                        END)::geometry, AP.support_shape))
                                                  FROM regulatory_zones as RZ
                                                  JOIN activity_productions as AP on RZ.shape && AP.support_shape
                                                   WHERE AP.campaign_id = 4 AND RZ.type IN ('BodyOfWater','Watercourse')
                                                  ;", manure_management_plan.campaign.id).first.values.first


    non_spreadable_charta = Charta.new_geometry(non_spreadable_zone_shape)
    #compute square meters area
    manure_management_plan.zones.each do |zone|
      info[:areas][zone.id] =  Charta.new_geometry(zone.support_shape).difference(non_spreadable_charta).area.in(Nomen::Unit.find(:hectare)).round(2)
    end

    return [non_spreadable_charta,info]
  end
end