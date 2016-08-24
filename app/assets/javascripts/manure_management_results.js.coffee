((E, $) ->
  'use strict'

  $(document).ready ->
    $el = $('input.manuring_result_form[data-map-editor]')

    getZoneInterventions = (zone_id) ->
      interventions = {}
      $.ajax
        url: $el.data('getZoneInterventionsUrl')
        method: 'POST'
        data: {zone_id: zone_id}
        error: (request, status, error) ->
          return {}
        success: (results) ->
          interventions = results["interventions"]
      return interventions

    updateNeedsDisplay = (interventions, feature, type) ->
      #Type refers to N/P/K ...
      quantity = 0
      zone_id = feature.properties.id
      input = feature.properties.results[type].input.value
      # TO DO iterate on interventions to update quantity
      # -----------
      $("<a class='manure_card_ratio'> #{quantity} / #{input} </a>").insertAfter($(".fieldset.#{"manure_zone"+zone_id}").find("a.title"))

    $el.on 'mapeditor:loaded', ->

    $el.on 'mapchange', ->

    $el.on 'mapeditor:serie_feature_add', (e, feature) ->
      if feature.properties.accordion
        $el.mapeditoraccordion 'insert', feature

    $el.on 'mapeditoraccordion:feature_select', (e, feature) ->
      $el.manureinterventionmenu 'insert', feature

    $el.on 'mapeditoraccordion:feature_update', (e, feature, attribute, type) ->

    $el.on 'mapeditoraccordion:feature_remove', (e, feature) ->

    $el.on 'mapeditoraccordion:feature_inserted', (e, feature) ->
      zone_id = feature.properties.id
      intervetions = getZoneInterventions(zone_id)
      for supply_nature of feature.properties.results
        updateNeedsDisplay(intervetions, feature, supply_nature)

  return false

) ekylibre, jQuery
