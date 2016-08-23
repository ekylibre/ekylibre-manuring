# coding: utf-8
# require 'calculus/manure_management_plan/method'
# require 'calculus/manure_management_plan/external'

module Manuring

  class PoitouCharentes2014 < ManuringApproach

    # http://www.poitou-charentes.developpement-durable.gouv.fr
    # Arrété 149/SGAR/2014 du 23/05/2014

    # Estimate "Pf"
    def estimated_needs(expected_yield = nil)
      # y
      expected_yield = estimate_expected_yield if expected_yield.nil?
      expected_yield ||= 0

      if @variety_nomen
        items = Manuring::Abaci::NmpPoitouCharentesAbacusThree2014Row.select do |i|
          @variety_nomen <= i.cultivation_variety &&
            (i.usage.blank? || i.usage.to_sym == @usage) &&
            (i.minimum_yield_aim.blank? || i.minimum_yield_aim <= expected_yield) &&
            (i.maximum_yield_aim.blank? || expected_yield <= i.maximum_yield_aim) &&
            (i.irrigated.blank? || (@irrigated && i.irrigated) || (!@irrigated && !i.irrigated))
        end
        # b
        if items.any?
          b = items.first.coefficient
        elsif @variety_nomen <= :triticum_aestivum
          b ||= 3
        elsif @variety_nomen <= :triticum_durum
          b ||= 3.5
        elsif @variety_nomen <= :zea
          b ||= 2.4
        else
          b = 0
        end
      end
      # if @variety and items = Manuring::Abaci::NmpPoitouCharentesAbacusThreeRow.best_match(:cultivation_variety, @variety.name) and items.any?
      #   b = items.first.coefficient
      # end
      expected_yield.in_kilogram_per_hectare * b / 100.0.to_d
    end

    # Estimate "S" soil_supply
    def soil_supplies
      values = estimated_supply

      # S
      s = 0.in_kilogram_per_hectare

      sets = crop_sets.map(&:name).map(&:to_s)

      # Céréales, Tournesol, Lin, Chanvre, Colza, Tabac et Portes graines
      if @variety_nomen && (@variety_nomen <= :poaceae || @variety_nomen <= :brassicaceae || @variety_nomen <= :medicago || @variety_nomen <= :helianthus || @variety_nomen <= :nicotiana || @variety_nomen <= :linum)
        # Si Type de sol est Argilo-calcaire ou terres rouges à châtaigniers
        if (@soil_nature_nomen <= :clay_limestone_soil || @soil_nature_nomen <= :chesnut_red_soil) || @variety_nomen > :nicotiana

          # S = Po + Mr + MrCi
          s = values[:soil_production] + values[:previous_cultivation_residue_mineralization] + values[:intermediate_cultivation_residue_mineralization]

        else
          # S = Pi + Ri + Mh + Mhp + Mr + MrCi + Rf
          s = values[:absorbed_nitrogen_at_opening] + values[:mineral_nitrogen_at_opening] + values[:humus_mineralization] +
                  values[:meadow_humus_mineralization] + values[:previous_cultivation_residue_mineralization] + values[:intermediate_cultivation_residue_mineralization] +
                  values[:nitrogen_at_closing]
        end

      end
      return s

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
      # C
      c = estimated_needs - soil_supplies

      sets = crop_sets.map(&:name).map(&:to_s)

      # Céréales, Tournesol, Lin, Chanvre, Colza, Tabac et Portes graines
      if @variety_nomen && (@variety_nomen <= :poaceae || @variety_nomen <= :brassicaceae || @variety_nomen <= :medicago || @variety_nomen <= :helianthus || @variety_nomen <= :nicotiana || @variety_nomen <= :linum)
        # Si Type de sol est Argilo-calcaire ou terres rouges à châtaigniers
        if (@soil_nature_nomen <= :clay_limestone_soil || @soil_nature_nomen <= :chesnut_red_soil) || @variety_nomen > :nicotiana
          # CAU = 0.8
          # X = [(Pf - Po - Mr - MrCi - Nirr) / CAU] - Xa
          #
          # X = [(C - Nirr) / CAU] - Xa
          fertilizer_apparent_use_coeffient = 0.8.to_d
          input = (((c - values[:irrigation_water_nitrogen]) / fertilizer_apparent_use_coeffient) - values[:organic_fertilizer_mineral_fraction])
        else
          # X = Pf - Pi - Ri - Mh - Mhp - Mr - MrCi - Nirr - Xa + Rf
          #
          # X = C - Nirr - Xa
          input = ( c - values[:irrigation_water_nitrogen] - values[:organic_fertilizer_mineral_fraction] )
        end

      end

      # Légumes / Arboriculture / Vignes : Dose plafond à partir d'abaques
      # X ≤ nitrogen_input_max – Nirr – Xa
      if @variety_nomen && (@variety_nomen <= :vitis || @variety_nomen <= :solanum_tuberosum || @variety_nomen <= :cucumis || sets.include?('gardening_vegetables'))
        input = values[:maximum_nitrogen_input] - values[:irrigation_water_nitrogen] - values[:organic_fertilizer_mineral_fraction]
      end
      # @zone.mark(:nitrogen_area_density, nitrogen_input.round(3), subject: :support)

      # if input < 0 then 0
      if input.to_d < 0.0
        input = 0.in_kilogram_per_hectare
      end

      # if input between 0 and 30 then 30
      if input.to_d > 0.0 && input.to_d <= 30.0
        input = 30.in_kilogram_per_hectare
      end

      # if input > MAX then MAX
      if input.to_d > values[:maximum_nitrogen_input].to_d
        input = values[:maximum_nitrogen_input]
      end

      return input
    end


    # Estimate "y"
    def estimate_expected_yield
      cultivation_varieties = (@variety_nomen ? @variety_nomen.self_and_parents : :undefined)
      capacity = @available_water_capacity.in_liter_per_square_meter
      # 1 / Calcul des références disponibles sur l'exploitation (au moins de cinq valeurs pour une condition de sol et de culture)
      # Moyenne des interventions de récolte sur les 5 dernières années

      # TODO

      # 2 / Référence par type de sol (Céréales)
      if capacity and cultivation_varieties and (@variety_nomen <= :triticosecale || @variety_nomen <= :triticum_aestivum || @variety_nomen <= :triticum_durum || @variety_nomen <= :hordeum) and @soil_nature and items = Manuring::Abaci::NmpPoitouCharentesAbacusTwoRow.where(cultivation_variety: cultivation_varieties.map(&:name), soil_nature: @soil_nature) and items = items.select { |i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity && capacity < i.maximum_available_water_capacity.in_liter_per_square_meter } and items.any?

        expected_yield = items.first.expected_yield.in_quintal_per_hectare
        puts "Method 2 for #{@activity_production.name} with #{capacity} capacity and #{expected_yield} yield computed ".inspect.red

      # 3 / Référence par département (Avoine, Seigle et Mélange de céréales)
      elsif cultivation_varieties and @administrative_area and items = Manuring::Abaci::NmpFranceCultivationYield.where(cultivation_variety: cultivation_varieties.map(&:name), administrative_area: @administrative_area) and (@variety_nomen <= :avena || @variety_nomen <= :secale || @variety_nomen <= :poaceae) and items.any?

        expected_yield = items.first.expected_yield.in_quintal_per_hectare
        puts "Method 3 for #{@activity_production.name} with #{expected_yield} yield computed ".inspect.red
      # 4 / Si aucuns des cas, receuil de la valeur saisie dans le budget
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
        expected_yield = @activity_production.estimate_yield(@campaign, options)
      end
      # puts "======================================================".red
      return expected_yield
    end



    # Estimate "Pi"
    def estimate_absorbed_nitrogen_at_opening
      quantity = 10.in_kilogram_per_hectare
      if @cultivation.blank? && @variety_nomen && (@variety_nomen <= :zea || @variety_nomen <= :sorghum || @variety_nomen <= :helianthus || @variety_nomen <= :linum || @variety_nomen <= :cannabis || @variety_nomen <= :nicotiana)
        quantity = 0.in_kilogram_per_hectare
      elsif @cultivation
        if count = @cultivation.leaf_count(at: @opened_at) and activity.nature.to_sym == :cereal_crops
          items = Manuring::Abaci::NmpPoitouCharentesAbacusFour2014Row.select do |item|
            item.minimum_leaf_count <= count && count <= item.maximum_leaf_count
          end
          if items.any?
            quantity = items.first.absorbed_nitrogen.in_kilogram_per_hectare
          end
        elsif @variety_nomen && @variety_nomen <= :brassica_napus && @cultivation.indicators_list.include?(:fresh_mass) && @cultivation.indicators_list.include?(:net_surface_area)
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
      # Question
      quantity = @mineral_nitrogen_at_opening.in_kilogram_per_hectare
      quantity ||= 15.in_kilogram_per_hectare
      return quantity
    end

    # Estimate "Mh"
    def estimate_humus_mineralization
      quantity = 30.in_kilogram_per_hectare
      sets = crop_sets.map(&:name).map(&:to_s)
      campaigns = @campaign.previous.reorder(harvest_year: :desc).limit(5)
      if sets.any? && @soil_nature_nomen
        items = Manuring::Abaci::NmpPoitouCharentesAbacusFive2014Row.select do |item|
          @soil_nature_nomen <= item.soil_nature && sets.include?(item.cereal_typology.to_s)
        end
        if items.any?
          # frequence d'apport de la matière organique
          organic_input_frequency = :without_organic_matter

            organic_fertilization_interventions = []
            for c in campaigns
              for target in @targets
               organic_fertilization_interventions << Intervention.of_campaign(c).of_actions(:organic_fertilization).with_targets(target)
              end
            end
            ip = organic_fertilization_interventions.count
            if ip >= 3
              organic_input_frequency = :three_years_organic_matter_frequency
            elsif ip >= 2
              organic_input_frequency = :three_to_five_years_organic_matter_frequency
            elsif ip >= 1
              organic_input_frequency = :five_years_organic_matter_frequency
            end
          quantity = items.first.send(organic_input_frequency).in_kilogram_per_hectare
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
      started_at = @activity_production.started_on.to_time || Time.new(@campaign.harvest_year - 1, 7, 15)
      stopped_at = @opened_at
      global_xa = []
      interventions = @activity_production.interventions.of_actions(:organic_fertilization).with_targets(@targets).between(started_at, stopped_at).where(nature: 'record')
      if interventions.any?
        for intervention in interventions
          # get the working area (hectare) concerning only the targets
          targets = intervention.targets.of_actors(@targets)
          targets_working_area = targets.with_working_zone.map(&:working_zone_area).sum.in(:hectare)
          # get the population of each intrant
          for input in intervention.inputs
            if i = input.product

              # get nitrogen concentration (t)
              t = estimate_nitrogen_concentration_inside_input_product(i)

              variant = i.variant_reference_name
              # get the period (month of intervention)
              month = intervention.started_at.strftime('%m')
              # get the input method
              input_method = 'on_top'
              # get the crop_set
              sets = crop_sets.map(&:name).map(&:to_s)
              # get keq
              items = Manuring::Abaci::NmpPoitouCharentesAbacusKeq2014Row.select do |item|
                variant.to_s == item.variant.to_s && sets.include?(item.crop.to_s) && month.to_i >= item.input_period_start.to_i && month.to_i <= item.input_period_stop.to_i
              end
              if items.any?
                i = items.first
                puts "Item #{i.label} with keq = #{i.keq} was found in abacus for intervention input #{variant.inspect} for #{intervention.name}".inspect.red
                keq = i.keq.to_d
              else
                puts "No items in abacus for intervention input #{variant.inspect}".inspect.red
              end
              # get net_mass (n) and working area for input density
              n = input.quantity
              if n.dimension == :mass_area_density && input.quantity_indicator_name == 'mass_area_density'
                q = n.to_d(:ton_per_hectare)
              elsif n.dimension == :mass && input.quantity_indicator_name == 'net_mass'
                net_mass = n.to_d(:ton)
                q = net_mass.to_d / targets_working_area.to_d if targets_working_area.to_d(:hectare) != 0
              end
              xa = t * keq * q if t && keq && q
              global_xa << xa
            end
          end
        end
      end
      quantity = global_xa.compact.sum.in_kilogram_per_hectare
      quantity
    end

    # Estimate Npro (nitrogen concentration in a product) **in kg N per ton**
    def estimate_nitrogen_concentration_inside_input_product(product)
      #TODO implement grab nitrogen concentration from a fertilizer analysis if the current variant of the product is concer by the fertilizer analysis
      # fertilizer_analysis = Analysis.of_nature("fertilizer_analysis")

      # get value from abacus

      if product.variant && product.variety && product.derivative_of

        v = Nomen::Variety[product.variety]
        d = Nomen::Variety[product.derivative_of]

        items = Manuring::Abaci::NmpFranceManuringInputNitrogenConcentration.select do |item|
          (product.variant == item.variant) || (v <= item.variety && d <= item.derivative_of)
        end
        if items.any?
          t = items.first.nitrogen_concentration.to_d
        # get the value in the product indicator
        elsif product.nitrogen_concentration
          t = product.nitrogen_concentration.to_d(:percent) * 10
        end
      end
    end

    # Estimate Rf
    def estimate_nitrogen_at_closing
      quantity = 0.in_kilogram_per_hectare
      if @variety_nomen && @variety_nomen <= :nicotiana
        quantity = 50.in_kilogram_per_hectare
      end
      if @soil_nature && capacity = @available_water_capacity.in_liter_per_square_meter
        items = Manuring::Abaci::NmpPoitouCharentesAbacusNineRow.select do |item|
          @soil_nature_nomen <= item.soil_nature && item.minimum_available_water_capacity.in_liter_per_square_meter <= capacity && capacity < item.maximum_available_water_capacity.in_liter_per_square_meter
        end
        quantity = items.first.rf.in_kilogram_per_hectare if items.any?
      end
      quantity
    end

    # Estimate Po
    def estimate_soil_production

      quantity = 0.in_kilogram_per_hectare
      sets = crop_sets.map(&:name).map(&:to_s)
      # TODO: find a way to retrieve water falls by API
      water_falls = @average_precipitation_between_october_and_march.in_liter_per_square_meter
      capacity = @available_water_capacity.in_liter_per_square_meter

      if capacity and sets


        if @variety_nomen && @variety_nomen <= :brassica_napus && plant_growth_indicator = @cultivation.density(:fresh_mass, :net_surface_area).to_d(:kilogram_per_hectare)

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
            item.plant_developpment == plant_growth.to_s &&
            sets.include?(item.crop.to_s) &&
             (item.precipitations_min.in_liter_per_square_meter <= water_falls &&
              water_falls < item.precipitations_max.in_liter_per_square_meter)
          end

        elsif @variety_nomen

          items = Manuring::Abaci::NmpPoitouCharentesAbacusTenRow.select do |item|
            (item.minimum_available_water_capacity.in_liter_per_square_meter <= capacity &&
             capacity < item.maximum_available_water_capacity.in_liter_per_square_meter) &&
             sets.include?(item.crop.to_s) &&
             (item.precipitations_min.in_liter_per_square_meter <= water_falls &&
              water_falls < item.precipitations_max.in_liter_per_square_meter)
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
      if department_item = @administrative_area and @variety_nomen
        cultivation_varieties = @variety_nomen.self_and_parents
        items = Manuring::Abaci::NmpFranceCultivationNitrogenInputMaxima.select do |i|
          @variety_nomen <= i.cultivation_variety && i.administrative_area.to_s == department_item.parent_area.to_s
        end
        if items.any?
          quantity = items.first.maximum_nitrogen_input.in_kilogram_per_hectare
        end
      end
      quantity
    end

  end
end
