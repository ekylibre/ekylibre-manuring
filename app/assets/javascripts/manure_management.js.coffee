((E, $) ->
  'use strict'

  $(document).ready ->

    $el = $('input.manuring_step_form[data-map-editor]')

    updateQuestion = (shape) ->
      if $el.is(':ui-mapeditor')
        data = shape: JSON.stringify shape
        if shape
          $.ajax
            url: $el.data('update-question')
            method: 'POST'
            data: data
            error: (request, status, error) ->
              false
            success: (status) ->
              true

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

    saveGeoreading = (shape) ->
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

          $.ajax
            url: $el.data('delete-url')
            method: 'DELETE'
            data: data
            error: (request, status, error) ->
              false
            success: (data) ->
              true

    allQuestionsFilled? = (shape)
      Object.keys(feature.properties.modalAttributes.group).forEach (key, index) =>
        question_group = feature.properties.modalAttributes.group[key]
        Object.keys(properties_group).forEach (key, index) =>
          question = question_group[key]
          if !(question.value && question.value.length > 0)
            return false
      return true


    updateActionMenu = (shape) ->
      if allQuestionsFilled?(shape)
        


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

    $el.on 'modal_validated', (e, shape) ->
      updateQuestion(shape)
      updateActionMenu(shape)
      console.log(shape)

    $el.on 'mapeditor:serie_feature_add', (e, shape) ->
      if shape.properties.actionMenu
        $el.mapeditoractionmenu 'insert', shape

    $el.on ' mapeditor:edit_feature_add', (e, shape) ->
      saveGeoreading(shape)




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
