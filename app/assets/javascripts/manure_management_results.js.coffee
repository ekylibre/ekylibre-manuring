((E, $) ->
  'use strict'

  $(document).ready ->
    $el = $('input.manuring_result_form[data-map-editor]')
    $intervention_menu_el = $('input.manuring_step_form[data-map-editor]')
    getZoneInterventions = (zone_id) ->
      interventions = {}
      $.ajax
        url: $el.data('getZoneInterventionsUrl')
        method: 'POST'
        data: {zone_id: zone_id}
        async: false
        error: (request, status, error) ->
          return {}
        success: (results) ->
          interventions = results["interventions"]
      return interventions

    getQuantity = (manure_zone_id) ->
      interventions = getZoneInterventions(manure_zone_id)
      quantity = 0
      for intervention in interventions
        quantity += parseFloat(intervention.quantity)
      return quantity

    updateNeedsDisplay = (interventions, feature, type) ->
      #Type refers to N/P/K ...
      zone_id = feature.properties.id
      quantity = getQuantity(zone_id)
      input = feature.properties.results[type].input.value
      # TO DO iterate on interventions to update quantity
      # -----------
      $("<a class='manure_card_ratio'> #{quantity} / #{input} </a>").insertAfter($(".manure_zone#{zone_id}").find("a.title"))

    $el.on 'mapeditor:loaded', ->

    $el.on 'mapchange', ->

    $el.on 'mapeditor:serie_feature_add', (e, feature) ->
      if feature.properties.accordion
        $el.mapeditoraccordion 'insert', feature

    $el.on 'mapeditoraccordion:feature_select', (e, feature) ->

    $el.on 'mapeditoraccordion:feature_update', (e, feature, attribute, type) ->

    $el.on 'mapeditoraccordion:feature_remove', (e, feature) ->

    $el.on 'mapeditoraccordion:feature_inserted', (e, feature) ->
      zone_id = feature.properties.id
      intervetions = getZoneInterventions(zone_id)
      for supply_nature of feature.properties.results
        updateNeedsDisplay(intervetions, feature, supply_nature)

    $el.on 'manure_intervention_menu:intervention_added', (e, results) ->
      for result in results.cards
        $content = $($.parseHTML(result.card))
        $icon = $content.find('i')
        $icon.replaceWith("<input id=#{result.id} class='manure_selected_icon' type='checkbox'>")
        manure_zone_id = result.id
        manure_zone_id = result.id
        $(".manure_zone#{manure_zone_id}").replaceWith($content)

        quantity = getQuantity(manure_zone_id)
        max = result.inputs["N"]        #  Sorry :S
        $("<a class='manure_card_ratio'> #{quantity} / #{max} </a>").insertAfter($(".manure_zone#{manure_zone_id}").find("a.title"))


  return false

) ekylibre, jQuery
