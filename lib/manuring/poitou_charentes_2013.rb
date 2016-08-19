# coding: utf-8
# require 'calculus/manure_management_plan/method'
# require 'calculus/manure_management_plan/external'

module Manuring
  class PoitouCharentes2013 < ManuringApproach

    def estimated_needs(expected_yield = nil)

      # Estimate "Pf"
      expected_yield = estimate_expected_yield if expected_yield.nil?

      b = 3
      if @variety
        items = Manuring::Abaci::NmpPoitouCharentesAbacusThreeRow.select do |i|
          @variety <= i.cultivation_variety &&
            (i.usage.blank? || i.usage.to_sym == @usage) &&
            (i.minimum_yield_aim.blank? || i.minimum_yield_aim <= expected_yield) &&
            (i.maximum_yield_aim.blank? || expected_yield <= i.maximum_yield_aim) &&
            (i.irrigated.blank? || (@irrigated && i.irrigated) || (!@irrigated && !i.irrigated))
        end
        if items.any?
          b = items.first.coefficient
        elsif @variety <= :zea
          b = 2.4
        end
      end
      # if @variety and items = Manuring::Abaci::NmpPoitouCharentesAbacusThreeRow.best_match(:cultivation_variety, @variety.name) and items.any?
      #   b = items.first.coefficient
      # end
      expected_yield.in_kilogram_per_hectare * b / 100.0.to_d

    end

    # compute all supply parameters
    def estimated_supply
      values = {}

      # Pi
      values[:absorbed_nitrogen_at_opening] = estimate_absorbed_nitrogen_at_opening

      # Ri
      values[:mineral_nitrogen_at_opening]  = estimate_mineral_nitrogen_at_opening

      # Mh
      values[:humus_mineralization]           = estimate_humus_mineralization

      # Mhp
      values[:meadow_humus_mineralization]    = estimate_meadow_humus_mineralization

      # Mr
      values[:previous_cultivation_residue_mineralization] = estimate_previous_cultivation_residue_mineralization

      # Mrci
      values[:intermediate_cultivation_residue_mineralization] = estimate_intermediate_cultivation_residue_mineralization

      # Nirr
      values[:irrigation_water_nitrogen] = estimate_irrigation_water_nitrogen

      # Xa
      values[:organic_fertilizer_mineral_fraction] = estimate_organic_fertilizer_mineral_fraction

      # Rf
      values[:nitrogen_at_closing] = estimate_nitrogen_at_closing

      # Po
      values[:soil_production] = estimate_soil_production

      # Xmax
      values[:maximum_nitrogen_input] = estimate_maximum_nitrogen_input

      return values
    end

    def estimated_input(values = {})

      values = estimated_supply

      # X
      input = 0.in_kilogram_per_hectare

      sets = crop_sets.map(&:name).map(&:to_s)

      # Céréales, Tournesol, Lin, Chanvre, Colza, Tabac et Portes graines
      if @variety && (@variety <= :poaceae || @variety <= :brassicaceae || @variety <= :medicago || @variety <= :helianthus || @variety <= :nicotiana || @variety <= :linum)
        # Si Type de sol est Argilo-calcaire ou terres rouges à châtaigniers
        if @soil_nature.include?(Nomen::SoilNature[:clay_limestone_soil]) || @soil_nature.include?(Nomen::SoilNature[:chesnut_red_soil]) and @variety and @variety > :nicotiana
          # CAU = 0.8
          # X = [(Pf - Po - Mr - MrCi - Nirr) / CAU] - Xa
          fertilizer_apparent_use_coeffient = 0.8.to_d
          input = (((estimated_needs -
                                       values[:soil_production] -
                                       values[:previous_cultivation_residue_mineralization] -
                                       values[:intermediate_cultivation_residue_mineralization] -
                                       values[:irrigation_water_nitrogen]) / fertilizer_apparent_use_coeffient) -
                                     values[:organic_fertilizer_mineral_fraction])
        else
          # X = Pf - Pi - Ri - Mh - Mhp - Mr - MrCi - Nirr - Xa + Rf
          input = (estimated_needs -
                                     values[:absorbed_nitrogen_at_opening] -
                                     values[:mineral_nitrogen_at_opening] -
                                     values[:humus_mineralization] -
                                     values[:meadow_humus_mineralization] -
                                     values[:previous_cultivation_residue_mineralization] -
                                     values[:intermediate_cultivation_residue_mineralization] -
                                     values[:irrigation_water_nitrogen] -
                                     values[:organic_fertilizer_mineral_fraction] +
                                     values[:nitrogen_at_closing])
        end

        if @soil_nature.include?(Nomen::SoilNature[:clay_limestone_soil])
          input *= 1.15.to_d
        else
          input *= 1.10.to_d
        end
      end

      # Légumes / Arboriculture / Vignes : Dose plafond à partir d'abaques
      # X ≤ nitrogen_input_max – Nirr – Xa
      if @variety && (@variety <= :vitis || @variety <= :solanum_tuberosum || @variety <= :cucumis || sets.include?('gardening_vegetables'))
        input = values[:maximum_nitrogen_input] - values[:irrigation_water_nitrogen] - values[:organic_fertilizer_mineral_fraction]
      end
      # @zone.mark(:nitrogen_area_density, nitrogen_input.round(3), subject: :support)

      # if input < 0 then 0
      if input.to_d < 0.0
        input = 0.in_kilogram_per_hectare
      end

      # if input > MAX then MAX
      if input.to_d > values[:maximum_nitrogen_input].to_d
        input = values[:maximum_nitrogen_input]
      end

      return input
    end


    # Estimate "y"
    def estimate_expected_yield
      puts 'PC 2013 ESTIMATE YIELD'.inspect.red
      cultivation_varieties = (@variety ? @variety.self_and_parents : :undefined)
      # puts "------------------------------------------------------".red
      # puts @options.inspect.yellow
      # puts cultivation_varieties.inspect.blue
      # puts soil_natures.inspect.white
      if items = Manuring::Abaci::NmpFranceCultivationYield.where(cultivation_variety: cultivation_varieties, administrative_area: @administrative_area || :undefined) and items.any? and (@variety <= :avena || @variety <= :secale)
        # puts items.inspect.green
        expected_yield = items.first.expected_yield.in_quintal_per_hectare
      elsif capacity = @available_water_capacity.in_liter_per_square_meter and items = Manuring::Abaci::NmpPoitouCharentesAbacusTwoRow.where(cultivation_variety: cultivation_varieties, soil_nature: @soil_nature) and items = items.select { |i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity && capacity < i.maximum_available_water_capacity.in_liter_per_square_meter } and items.any?
        # puts items.inspect.green
        expected_yield = items.first.expected_yield.in_quintal_per_hectare
      else
        variety = nil
        if @activity_production.usage == 'grain'
          variety = :grain
        elsif @activity_production.usage == 'fodder'
          variety = :grass
        end
        # return budget estimate yield
        options = {}
        options[variety] = variety
        expected_yield = @activity_production.estimate_yield(options)
      end
      # puts "======================================================".red
      expected_yield
    end



    # Estimate "Pi"
    def estimate_absorbed_nitrogen_at_opening
      quantity = 10.in_kilogram_per_hectare
      if @cultivation.blank? && @variety && (@variety <= :zea || @variety <= :sorghum || @variety <= :helianthus || @variety <= :linum || @variety <= :cannabis || @variety <= :nicotiana)
        quantity = 0.in_kilogram_per_hectare
      elsif @cultivation
        if count = @cultivation.leaf_count(at: @opened_at) and activity.nature.to_sym == :cereal_crops
          items = Manuring::Abaci::NmpPoitouCharentesAbacusFourRow.select do |item|
            item.minimum_leaf_count <= count && count <= item.minimum_leaf_count
          end
          if items.any?
            quantity = items.first.absorbed_nitrogen.in_kilogram_per_hectare
          end
        elsif @variety && @variety <= :brassica_napus && @cultivation.indicators_list.include?(:fresh_mass) && @cultivation.indicators_list.include?(:net_surface_area)
          items = Manuring::Abaci::NmpPoitouCharentesAbacusTwelveRow.select do |item|
            @administrative_area <= item.administrative_area
          end
          if items.any?
            quantity = (items.first.coefficient * @cultivation.fresh_mass(at: @opened_at).to_f(:kilogram) / @cultivation.net_surface_area(at: @opened_at).to_f(:square_meter)).in_kilogram_per_hectare
          end
        end
      end
      quantity
    end

    # Estimate "Ri"
    def estimate_mineral_nitrogen_at_opening
      quantity = @mineral_nitrogen_at_opening.in_kilogram_per_hectare
      quantity ||= 15.in_kilogram_per_hectare
      if quantity < 5.in_kilogram_per_hectare
        quantity = 5.in_kilogram_per_hectare
      elsif quantity > 35.in_kilogram_per_hectare
        quantity = 35.in_kilogram_per_hectare
      end
      quantity
    end

    # Estimate "Mh"
    def estimate_humus_mineralization
      quantity = 30.in_kilogram_per_hectare
      sets = crop_sets.map(&:name).map(&:to_s)
      campaigns = @campaign.previous.reorder(harvest_year: :desc)
      if sets.any? && @soil_nature
        items = Manuring::Abaci::NmpPoitouCharentesAbacusFiveRow.select do |item|
          @soil_nature <= item.soil_nature &&
            sets.include?(item.cereal_typology.to_s)
        end
        if items.any?
          # if there are animal's activities on farm in campaign
          if Activity.of_campaign(campaigns).of_families(:animal_farming).any?
            # if animals moved on cultivable_zones in previous campaign then :husbandry_with_mixed_crop else :husbandry

            pasturing_interventions = []
            for c in campaigns
             pasturing_interventions << Intervention.of_campaign(c).of_nature(:pasturing)
            end
            if pasturing_interventions.compact.any?
              typology = :husbandry_with_mixed_crop
            else
              typology = :husbandry
            end
          # elsif all production on the campagin is link to a crop_set :cereals then :cereal_crop
          elsif Activity.of_campaign(campaigns).of_families(:cereal_crops).count == Activity.of_campaign(campaigns).of_families(:vegetal_crops).count
            typology = :cereal_crop
          else
            typology = :mixed_crop
          end
          quantity = items.first.send(typology).in_kilogram_per_hectare
        end
      end
      quantity
    end

    # Estimate "Mhp"
    def estimate_meadow_humus_mineralization
      quantity = 0.in_kilogram_per_hectare
      rank = 1
      found = nil
      for campaign in @campaign.previous.reorder(harvest_year: :desc)
        for activity_production in campaign.activity_productions.where(cultivable_zone_id: @activity_production.cultivable_zone.id)
          variety_support = Nomen::Variety.find(activity_production.production_variety)
          if variety_support <= :poa
            found = activity_production
            break
          end
        end
        break if found
        rank += 1
      end
      if rank > 0 && found && cultivation = found.cultivation
        age = (cultivation.dead_at - cultivation.born_at) / 1.month
        season = ([9, 10, 11, 12].include?(cultivation.dead_at.month) ? :autumn : [3, 4, 5, 6].include?(cultivation.dead_at.month) ? :spring : nil)
        items = Manuring::Abaci::NmpPoitouCharentesAbacusSixRow.select do |item|
          item.minimum_age <= age && age <= item.maximum_age &&
            item.rank == rank
        end
        quantity = items.first.quantity.in_kilogram_per_hectare if items.any?
      end
      quantity
    end

    # Estimate "Mr"
    def estimate_previous_cultivation_residue_mineralization
      quantity = 0.in_kilogram_per_hectare
      # get the previous cultivation variety on the current support storage
      previous_variety = nil
      for campaign in @campaign.previous.reorder(harvest_year: :desc)
        for activity_production in campaign.activity_productions.where(cultivable_zone_id: @activity_production.cultivable_zone.id)
          # if an implantation intervention exist, get the plant output
          if previous_implantation_intervention = activity_production.interventions.of_nature(:implantation).where(state: :done).order(:started_at).last
            if previous_cultivation = previous_implantation_intervention.casts.of_generic_role(:output).first.actor
              previous_variety = Nomen::Variety.find(previous_cultivation.variety)
              previous_cultivation_dead_at = previous_cultivation.dead_at
              break
            end
            break if previous_variety
          # elsif get the production_variant
          elsif activity_production.production_variety
            previous_variety = Nomen::Variety.find(activity_production.production_variety)
            break
          end
          break if previous_variety
        end
        break if previous_variety
      end

      if previous_variety
        # find corresponding crop_sets to previous_variety
        previous_crop_sets = Nomen::CropSet.list.select do |i|
          i.varieties.detect do |v|
            previous_variety <= v
          end
        end
        previous_sets = previous_crop_sets.map(&:name).map(&:to_s)
      end
      # build variables for abacus 7
      # find the previous crop age in months
      if previous_cultivation && previous_cultivation.dead_at && previous_cultivation.born_at
        previous_crop_age = ((previous_cultivation.dead_at - previous_cultivation.born_at) / (3600 * 24 * 30)).to_i
      else
        previous_crop_age = 1
      end
      # find the previous crop destruction period date in format MMDD
      if previous_cultivation && previous_cultivation.dead_at
        previous_crop_destruction_period = previous_cultivation.dead_at.strftime('%m%d')
      else
        previous_crop_destruction_period = '0831'
      end
      # find the current crop implantation period date in format MMDD
      if @cultivation
        current_crop_implantation_period = @cultivation.born_at.strftime('%m%d')
      else
        current_crop_implantation_period = '0315'
      end
      # find items in abacus 7
      if previous_sets && previous_crop_age && previous_crop_destruction_period && current_crop_implantation_period
        items = Manuring::Abaci::NmpPoitouCharentesAbacusSevenRow.select do |item|
          previous_sets.include?(item.previous_crop.to_s) && (item.previous_crop_minimum_age.to_i <= previous_crop_age.to_i && previous_crop_age.to_i < item.previous_crop_maximum_age.to_i) && (item.previous_crop_destruction_period_start.to_i <= previous_crop_destruction_period.to_i && previous_crop_destruction_period.to_i < item.previous_crop_destruction_period_stop.to_i) && current_crop_implantation_period.to_i >= item.current_crop_implantation_period_start.to_i
        end
        quantity = items.first.quantity.in_kilogram_per_hectare if items.any?
      end
      quantity
    end

    # Estimate "Mrci"
    def estimate_intermediate_cultivation_residue_mineralization
      quantity = 0.in_kilogram_per_hectare
      sets = crop_sets.map(&:name).map(&:to_s)
      if sets.any? && sets.include?('spring_crop')
        if @activity_production.support
          previous_variety = nil
          for campaign in @campaign.previous.reorder(harvest_year: :desc)
            for activity_production in campaign.activity_productions.where(cultivable_zone_id: @activity_production.cultivable_zone.id)
              # if an implantation intervention exist, get the plant output
              if previous_implantation_intervention = activity_production.interventions.of_nature(:implantation).where(state: :done).order(:started_at).last
                if previous_cultivation = previous_implantation_intervention.casts.of_generic_role(:output).actor
                  previous_variety = previous_cultivation.variety
                  previous_cultivation_dead_at = previous_cultivation.dead_at
                  break
                end
                break if previous_variety
              # elsif get the production_variant
              elsif activity_production.production_variety
                previous_variety = Nomen::Variety.find(activity_production.production_variety)
                break
              end
              break if previous_variety
            end
            break if previous_variety
          end

          if previous_variety
            # find corresponding crop_sets to previous_variety
            previous_crop_sets = Nomen::CropSet.list.select do |i|
              i.varieties.detect do |v|
                previous_variety <= v
              end
            end
            previous_sets = previous_crop_sets.map(&:name).map(&:to_s)
          end

          # build variables for abacus 11
          previous_crop_destruction_period = '0831'
          previous_crop_plants_growth_level = 'hight'
          if previous_cultivation && previous_cultivation.dead_at
            previous_crop_destruction_period = previous_cultivation.dead_at.strftime('%m%d')
            if previous_cultivation.get(:plant_growth_level)
              previous_crop_plants_growth_level = previous_cultivation.get(:plant_growth_level)
            end
          end
          if previous_sets && previous_crop_destruction_period && previous_crop_plants_growth_level
            # get value from abacus 11
            items = Manuring::Abaci::NmpPoitouCharentesAbacusElevenRow.select do |item|
              previous_sets.include?(item.intermediate_crop_variety.to_s) && (item.intermediate_crop_destruction_period_start.to_i <= previous_crop_destruction_period.to_i && previous_crop_destruction_period.to_i < item.intermediate_crop_destruction_period_stop.to_i) && previous_crop_plants_growth_level.to_s == item.growth_level.to_s
            end
            quantity = items.first.mrci.in_kilogram_per_hectare if items.any?
          end
        end
      end
      quantity
    end

    # Estimate Nirr
    def estimate_irrigation_water_nitrogen
      quantity = 0.in_kilogram_per_hectare
      if @irrigated
        budget_ids = ActivityBudget.where(activity_id: @activity_production.activity_id, campaign_id: @activity_production.campaign_id).pluck(:id)
        water_budget_items = ActivityBudgetItem.where(activity_budget_id: budget_ids, variant_id: ProductNatureVariant.of_variety(:water).map(&:id))
        s = @activity_production.size
        v = 0
        for item in water_budget_items
          m = Measure.new(item.quantity, item.variant_unit)
          if item.computation_method == :per_working_unit
            input_water = (m.to_d(:liter) / s.to_d(:square_meter))
          end
          v += input_water.to_d.round(2)
        end
        if v >= 100.00
          # TODO: find an analysis for nitrogen concentration of input water for irrigation 'c'
          c = 40
          quantity = ((v / 100) * (c / 4.43)).in_kilogram_per_hectare
        end
      end
      quantity
    end

    # Estimate Xa
    def estimate_organic_fertilizer_mineral_fraction
      quantity = 0.in_kilogram_per_hectare
      # FIXME: be careful : started_at forced to 15/07/N-1
      started_at = Time.new(@campaign.harvest_year - 1, 7, 15)
      stopped_at = @opened_at
      global_xa = []
      if interventions = @activity_production.interventions.real.where(state: 'done').of_nature(:soil_enrichment).between(started_at, stopped_at)
        for intervention in interventions
          # get the working area (hectare)
          working_area = intervention.casts.of_role('soil_enrichment-target').first.population
          # get the population of each intrant
          for input in intervention.casts.of_role('soil_enrichment-input')
            if i = input.actor
              # get nitrogen concentration (t) in percent
              t = i.nitrogen_concentration.to_d(:percent)
              # get the keq coefficient from abacus_8
              # get the variant reference_name
              variant = i.variant_reference_name
              # get the period (month of intervention)
              month = intervention.started_at.strftime('%m')
              # get the input method
              input_method = 'on_top'
              # get the crop_set
              sets = crop_sets.map(&:name).map(&:to_s)
              # get keq
              items = Manuring::Abaci::NmpPoitouCharentesAbacusEightRow.select do |item|
                variant.to_s == item.variant.to_s && sets.include?(item.crop.to_s) && month.to_i >= item.input_period_start.to_i
              end
              keq = items.first.keq.to_d if items.any?
              # get net_mass (n) and working area for input density
              n = i.net_mass(input).to_d(:ton)
              q = (n / working_area).to_d if working_area != 0
              xa = (t / 10) * keq * q if t && keq && q
              global_xa << xa
            end
          end
        end
      end
      quantity = global_xa.compact.sum.in_kilogram_per_hectare
      quantity
    end

    # Estimate Rf
    def estimate_nitrogen_at_closing
      quantity = 0.in_kilogram_per_hectare
      if @variety && @variety <= :nicotiana
        quantity = 50.in_kilogram_per_hectare
      end
      if @soil_nature && capacity = @available_water_capacity.in_liter_per_square_meter
        items = Manuring::Abaci::NmpPoitouCharentesAbacusNineRow.select do |item|
          @soil_nature <= item.soil_nature && item.minimum_available_water_capacity.in_liter_per_square_meter <= capacity && capacity < item.maximum_available_water_capacity.in_liter_per_square_meter
        end
        quantity = items.first.rf.in_kilogram_per_hectare if items.any?
      end
      quantity
    end

    # Estimate Po
    def estimate_soil_production
      quantity = 0.in_kilogram_per_hectare
      sets = crop_sets.map(&:name).map(&:to_s)
      # TODO: find a way to retrieve water falls
      water_falls = 380.in_liter_per_square_meter

      if capacity = @available_water_capacity.in_liter_per_square_meter and sets = crop_sets.map(&:name).map(&:to_s)
        if @variety && @variety <= :brassica_napus && plant_growth_indicator = @cultivation.density(:fresh_mass, :net_surface_area).to_d(:kilogram_per_hectare)

          if plant_growth_indicator <= 0.4
            plant_growth = 'low'
          elsif plant_growth_indicator > 0.4 && plant_growth_indicator <= 1.6
            plant_growth = 'medium'
          elsif plant_growth_indicator > 1.6
            plant_growth = 'high'
          else
            plant_growth = 'low'
          end

          items = Manuring::Abaci::NmpPoitouCharentesAbacusTenRow.select do |item|
            item.plant_developpment == plant_growth.to_s && sets.include?(item.crop.to_s) && (item.precipitations_min.in_liter_per_square_meter <= water_falls && water_falls < item.precipitations_max.in_liter_per_square_meter)
          end

        elsif @variety

          items = Manuring::Abaci::NmpPoitouCharentesAbacusTenRow.select do |item|
            (item.minimum_available_water_capacity.in_liter_per_square_meter <= capacity && capacity < item.maximum_available_water_capacity.in_liter_per_square_meter) && sets.include?(item.crop.to_s) && (item.precipitations_min.in_liter_per_square_meter <= water_falls && water_falls < item.precipitations_max.in_liter_per_square_meter)
          end
        else
          items = {}
        end
        quantity = items.first.po.in_kilogram_per_hectare if items.any?
      end
      quantity
    end

    def estimate_maximum_nitrogen_input
      quantity = 170.in_kilogram_per_hectare
      if department_item = @administrative_area and @variety
        cultivation_varieties = @variety.self_and_parents
        items = Manuring::Abaci::NmpFranceCultivationNitrogenInputMaxima.select do |i|
          @variety <= i.cultivation_variety && i.administrative_area.to_s == department_item.parent_area.to_s
        end
        if items.any?
          quantity = items.first.maximum_nitrogen_input.in_kilogram_per_hectare
        end
      end
      quantity
    end

  end
end
