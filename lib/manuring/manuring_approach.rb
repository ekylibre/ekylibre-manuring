module Manuring

    class ManuringApproach < Calculus::ManureManagementPlan::Approach

      def initialize(application)
        super(application)
        @variety = Nomen::Variety[manure_management_plan_zone.cultivation_variety]
        @soil_nature = Nomen::SoilNature[manure_management_plan_zone.soil_nature] 
        @administrative_area = manure_management_plan_zone.administrative_area
        @available_water_capacity = 0
        @irrigated = manure_management_plan_zone.irrigated
        @campaign = manure_management_plan_zone.campaign
        @zone = manure_management_plan_zone
        @activity_production = manure_management_plan_zone.activity_production
        @cultivation = manure_management_plan_zone.activity_production.current_cultivation
        @opened_at = manure_management_plan_zone.opened_at
        @mineral_nitrogen_at_opening = 0.0
      end
      
      def crop_sets
        return [] unless @variety
        @crop_sets ||= Nomen::CropSets.list.select do |i|
          i.varieties.detect do |v|
            @variety <= v
          end
        end
        return @crop_sets
      end


    end

end