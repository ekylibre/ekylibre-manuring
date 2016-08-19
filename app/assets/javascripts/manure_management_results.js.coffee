((E, $) ->
  'use strict'

  $(document).ready ->

    $el = $('input.manuring_result_form[data-map-editor]')
    $el.on 'mapeditor:loaded', ->
      map = $el.mapeditor 'get_map'

    $el.on 'mapchange', ->

    $el.on 'mapeditor:serie_feature_add', (e, feature) ->

    $el.on 'mapeditoraccordion:feature_select', (e, shape) ->

    $el.on 'mapeditoraccordion:feature_update', (e, shape, attribute, type) ->

    $el.on 'mapeditoraccordion:feature_remove', (e, shape) ->

  return false

) ekylibre, jQuery
