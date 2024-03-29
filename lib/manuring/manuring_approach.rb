module Manuring
  class ManuringApproach < Calculus::ManureManagementPlan::Approach
    def initialize(application)
      super(application)
      @variety = manure_management_plan_zone.cultivation_variety
      @variety_nomen = Nomen::Variety[manure_management_plan_zone.cultivation_variety]
      @soil_nature = manure_management_plan_zone.soil_nature
      @soil_nature_nomen = Nomen::SoilNature[manure_management_plan_zone.soil_nature]
      @administrative_area = manure_management_plan_zone.administrative_area
      @available_water_capacity = (parameters['available_water_capacity'] || 0).to_d
      @average_precipitation_between_october_and_march = (parameters['average_precipitation_between_october_and_march'] || 350).to_d
      @irrigated = manure_management_plan_zone.irrigated
      @usage = manure_management_plan_zone.usage
      @usage_nomen = Nomen::ProductionUsage[manure_management_plan_zone.usage]
      @campaign = manure_management_plan_zone.campaign
      @zone = manure_management_plan_zone
      @activity_production = manure_management_plan_zone.activity_production
      @cultivable_zone = manure_management_plan_zone.activity_production.cultivable_zone
      @cultivation = manure_management_plan_zone.activity_production.current_cultivation
      @opened_at = manure_management_plan_zone.opened_at
      @mineral_nitrogen_at_opening = (parameters['mineral_nitrogen_in_soil_at_opening'] || 0.0).to_d
      @targets = Product.where(id: manure_management_plan_zone.activity_production.distributions.pluck(:target_id))
      # for animal balance
      @milk_annual_production_from_all_adult_female_cow = manure_management_plan_zone.plan.milk_annual_production_in_liter
      @external_building_attendance_in_month_from_all_adult_female_cow = manure_management_plan_zone.plan.external_building_attendance_in_month
    end

    def crop_sets
      return [] unless @variety_nomen
      @crop_sets ||= Nomen::CropSets.list.select do |i|
        i.varieties.detect do |v|
          @variety_nomen <= v
        end
      end
      @crop_sets
    end

    # compute global daily nitrogen production (in kilogram_per_day)
    def annual_nitrogen_animal_output
      # get all animals in current campaign
      animals = ::Animal.at(@opened_at)
      # return global daily nitrogen production for these animals
      (daily_nitrogen_production(animals).to_d * 365).in_kilogram.round(2)
    end

    # compute average annual milk production per animal from annual milk production
    def average_annual_milk_animal_production_from_milk_production
      # count all animal producing milkin the period
      animal_milk_member_count = []
      animal_milk_member_count << 55

      if @milk_annual_production_from_all_adult_female_cow
        (@milk_annual_production_from_all_adult_female_cow / animal_milk_member_count.compact.sum) / 0.92
      else
        return nil
      end
    end

    # compute daily nitrogen production for animals
    def daily_nitrogen_production(animals)
      global_quantity = []
      avg_milk = average_annual_milk_animal_production_from_milk_production

      for animal in animals

        return nil unless animal.is_a? Animal

        # set variables with default values
        quantity = 0.in_kilogram_per_day
        animal_milk_production = nil

        # get data
        # age (if born_at not present then animal has 24 month)
        animal_age = 24
        animal_age = (animal.age / (3600 * 24 * 30)).to_d if animal.age

        # production (if a cow, get annual milk production)
        if Nomen::Varieties[animal.variety] <= :bos && animal.able_to?('produce(milk)')
          if avg_milk
            animal_milk_production = avg_milk
          elsif animal.milk_daily_production
            animal_milk_production = (animal.milk_daily_production * 305).to_d
          end
        end

        if animal_milk_production && animal_age && @external_building_attendance_in_month_from_all_adult_female_cow
          items = Manuring::Abaci::NmpFranceAnimalNitrogenProduction.select do |item|
            item.minimum_age <= animal_age.to_i &&
              animal_age.to_i < item.maximum_age &&
              item.minimum_milk_production <= animal_milk_production.to_i &&
              animal_milk_production.to_i < item.maximum_milk_production &&
              @external_building_attendance_in_month_from_all_adult_female_cow.to_d < item.maximum_outside_presence &&
              @external_building_attendance_in_month_from_all_adult_female_cow.to_d > item.minimum_outside_presence.to_d &&
              item.variant.to_s == animal.variant.reference_name.to_s
          end
        elsif animal_age
          items = Manuring::Abaci::NmpFranceAnimalNitrogenProduction.select do |item|
            item.minimum_age <= animal_age.to_i &&
              animal_age.to_i < item.maximum_age &&
              item.variant.to_s == animal.variant.reference_name.to_s
          end
        end

        if items.any?
          quantity_per_year = items.first.quantity
          quantity = (quantity_per_year / 365).in_kilogram_per_day
        end

        global_quantity << quantity

      end

      global_quantity.compact.sum
    end
  end
end
