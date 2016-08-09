module Manuring

    class ManuringApproach < Calculus::ManureManagementPlan::Approach
      
      def initialize(application)
        super(application)
        @variety = manure_management_plan_zone.cultivation_variety
        @administrative_area = manure_management_plan_zone.administrative_area
      end
      
      # Estimate "y"
      def estimate_expected_yield
        require 'colored' unless defined? Colored
        expected_yield = budget_estimate_expected_yield
        puts expected_yield.inspect.red
        
        cultivation_varieties = (@variety ? @variety.self_and_parents : :undefined)
        # puts "------------------------------------------------------".red
        # puts @options.inspect.yellow
        # puts cultivation_varieties.inspect.blue
        # puts soil_natures.inspect.white
        if items = Manuring::Abaci::NmpFranceCultivationYield.where(cultivation_variety: cultivation_varieties, administrative_area: @administrative_area || :undefined) and items.any? and (@variety <= :avena || @variety <= :secale)
          # puts items.inspect.green
          expected_yield = items.first.expected_yield.in_quintal_per_hectare
        elsif capacity = @options[:available_water_capacity].in_liter_per_square_meter and items = Manuring::Abaci::NmpPoitouCharentesAbacusTwoRow.where(cultivation_variety: cultivation_varieties, soil_nature: soil_natures) and items = items.select { |i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity && capacity < i.maximum_available_water_capacity.in_liter_per_square_meter } and items.any?
          # puts items.inspect.green
          expected_yield = items.first.expected_yield.in_quintal_per_hectare
        else
          variety = nil
          if @support.usage == 'grain'
            variety = :grain
          elsif @support.usage == 'fodder'
            variety = :grass
          end
          expected_yield = @support.estimate_yield(variety: variety)
        end
        # puts "======================================================".red
        expected_yield
      end
      
    end

end