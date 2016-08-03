((E, $) ->
  'use strict'






  $(document).ready ->

    $el = $('input.manuring_step_form[data-map-editor]')


    updateMap = () ->
      if $el.is(':ui-mapeditor')
        newShapes = JSON.parse $el.val()
        data =
          shape: JSON.stringify newShapes
          attributes: $el.data('attributes')

        if newShapes
          $.ajax
            url: $el.data('update-url')
            method: 'POST'
            data: data
            error: (request, status, error) ->
              false
            success: (status) ->
              true

    InsertToMap = (shape) ->
      if $el.is(':ui-mapeditor')
        newShapes = shape
        data =
          shape: JSON.stringify newShapes
          attributes: $el.data('attributes')

        if newShapes
          $.ajax
            url: $el.data('create-url')
            method: 'POST'
            data: data
            error: (request, status, error) ->
              false
            success: (data) ->
              $el.mapeditor 'updateFeatureProperties',shape.properties.internal_id, 'id', data.id

    deleteFromMap = (shape) ->
      if $el.is(':ui-mapeditor')
        if shape
          data =
            shape: JSON.stringify shape
            attributes: $el.data('attributes')
          console.log(shape)

          $.ajax
            url: $el.data('delete-url')
            method: 'DELETE'
            data: data
            error: (request, status, error) ->
              false
            success: (data) ->
              true

    $el.on 'mapeditor:loaded', ->

      cap_geojson = $el.data('cap-geojson')
      geojson = $el.data('firstrun-geojson')

      $el.mapeditor 'show', cap_geojson if cap_geojson? and Object.keys(cap_geojson).length
      $el.mapeditor 'edit', geojson if geojson? and Object.keys(geojson).length
      $el.mapeditor 'view', 'show' if cap_geojson? and Object.keys(cap_geojson).length
      $el.mapeditor 'view', 'edit' if geojson? and Object.keys(geojson).length

      updateMap()

    $el.on 'mapchange', =>
      updateMap()

    $el.on 'mapeditor:feature_add', (e, shape) ->
      InsertToMap(shape)
      $el.mapeditoractionmenu 'insert', shape

    $el.on 'mapeditor:feature_update', (e, shape) ->

      $el.mapeditoractionmenu 'update', shape
      $el.mapeditor 'update'

    $el.on 'mapeditoractionmenu:feature_select', (e, shape) ->
      layer = $el.mapeditor 'findLayer', $(shape).data('internal-id')
      $el.mapeditor 'navigateToLayer', layer unless layer is undefined

    $el.on 'mapeditor:feature_delete', (e, shape) ->
      deleteFromMap(shape)
      $el.mapeditoractionmenu 'removeFromGeoJSON', shape

    $el.on 'mapeditoractionmenu:feature_update', (e, shape, attribute, type) ->
      $el.mapeditor 'update'

    $el.on 'mapeditoractionmenu:feature_remove', (e, shape) ->
      $('#delete-shape').data('shape', shape)

      $('#delete-shape').on 'show.bs.modal', (e) ->
        shape = $(this).data('shape')
        layer = $el.mapeditor 'findLayer', $(shape).data('internal-id')
        $el.mapeditor 'navigateToLayer', layer if layer?

        $(e.currentTarget).on 'click', "*[data-action='delete']", () ->
          $el.mapeditor 'removeLayer', layer unless layer is undefined
          $el.mapeditoractionmenu 'remove', shape

          $el.mapeditor 'update'

          $('#delete-shape').modal('hide')

      $('#delete-shape').modal('show')

  return false

) ekylibre, jQuery
