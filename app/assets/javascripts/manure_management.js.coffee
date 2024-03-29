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

    allQuestionsFilled = (questions) ->
      #Check if every key has a value
      filled = true
      for supply_nature of questions
        question_group = questions[supply_nature]
        for question_key of question_group
          if !question_group[question_key]
            return false
      return filled

    get_questions = (popup_content) ->
      questions = {}
      jquery_content = $($.parseHTML(popup_content))
      jquery_content.find('input.question_input').each (index, input) =>
        supply_nature = $(input).attr('supply_nature')
        questions[supply_nature] = {} unless questions[supply_nature]
        questions[supply_nature][$(input).attr('name')] =  $(input).val()
      return questions

    updateActionMenu = (questions, internal_id) ->
      if allQuestionsFilled(questions)
        $el.mapeditoractionmenu 'apply', internal_id, ($el) ->
          $el.addClass 'question-filled'
          $el.removeClass 'question-empty'
      else
        $el.mapeditoractionmenu 'apply', internal_id, ($el) ->
          $el.removeClass 'question-filled'
          $el.addClass 'question-empty'

    $el.on 'mapeditor:loaded', ->
      cap_geojson = $el.data('cap-geojson')
      geojson = $el.data('firstrun-geojson')

      $el.mapeditor 'show', cap_geojson if cap_geojson? and Object.keys(cap_geojson).length
      $el.mapeditor 'edit', geojson if geojson? and Object.keys(geojson).length
      $el.mapeditor 'view', 'show' if cap_geojson? and Object.keys(cap_geojson).length
      $el.mapeditor 'view', 'edit' if geojson? and Object.keys(geojson).length

      map = $el.mapeditor 'get_map'

      map.on 'popupopen', (popup_event) =>
        $('.update-questions').on 'click', (e) =>
          zone_id = $('.popup-content').attr('manure_zone_id')
          layer_id = $('.popup-header').find('.leaflet-popup-warning').attr('internal_id')
          layer = $el.mapeditor 'findLayer', layer_id
          questions = {}
          $('.popup-content').find('input.question_input').each (index, input) =>
            supply_nature = $(input).attr('supply_nature')
            questions[supply_nature] = {} unless questions[supply_nature]
            questions[supply_nature][$(input).attr('name')] =  $(input).val()

          data =
            zone_id: zone_id
            questions: questions
          #Ajax to update model with questions answers
          $.ajax
            url: $el.data('updateQuestions')
            method: 'POST'
            data: data
            error: (request, status, error) ->
              false
            success: (data) =>
              feature = layer.feature

              #update popup content
              popup_content = feature.properties.popup_content
              jquery_content = $($.parseHTML(popup_content))
              jquery_content.find('input.question_input').each (index, input) =>
                supply_nature = $(input).attr('supply_nature')
                name = $(input).attr('name')
                $(input).attr('value',questions[supply_nature][$(input).attr('name')])
              feature.properties.popup_content = (((jquery_content.wrap("<div class='manure_popup'></div>")).parent()).html())

              #update action_menu
              updateActionMenu(questions, feature.properties.internal_id)

              #Create new popup with updated content
              $el.mapeditor 'popupizeSerie', feature, layer

          popup_event.target.closePopup()

      $('.item_button').each (index, button) =>
        $(button).on "click", (e) =>
          e.stopPropagation()
          id = $(button).closest('.item').attr('data-internal-id')
          layer = $el.mapeditor 'findLayer', id
          $el.mapeditor 'navigateToLayer', layer unless layer is undefined
          layer.openPopup()

      updateMap()
    $el.on 'mapchange', =>
      updateMap()

    $el.on 'mapeditor:serie_feature_add', (e, feature) ->
      if feature.properties.actionMenu
        $el.mapeditoractionmenu 'insert', feature
        questions = get_questions(feature.properties.popup_content)
        updateActionMenu(questions, feature.properties.internal_id)

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
