(($) ->
  "use strict"

  $.widget "ui.mapeditoraccordion",
    options:
      box:
        height: null
        width: null
      customClass: ''

    _create: ->

      $.extend(true, @options, @element.data("accordion"))

      @$accordion = $('<div>', class: "accordion #{this.options.customClass}").insertAfter(@element)
      widget = this

      @_resize()

      widget.element.trigger "mapeditoraccordion:loaded"

    template: (properties) ->
      return $($.parseHTML(properties["field_set_template"]))

    insert: (geojson) ->
      if geojson.properties?
        $render = @template(geojson.properties)
        @$accordion.append $render
        $render.on 'click', (e) =>
          $(@element).trigger('mapeditoraccordion:feature_select',e.currentTarget)

    update: (geojson) ->
      if geojson.properties?
        $element = @$accordion.find("div[data-internal-id='#{geojson.properties.internal_id}']")
        if $element
          $render = @template(geojson.properties)
          $element.html($render.html())

          $element.addClass 'updated'
          setTimeout(() ->
            $element.removeClass 'updated'
          ,1000)

    apply: (internal_id,fun) ->
      $element = @$accordion.find("div[data-internal-id='#{internal_id}']")
      fun($element)

    remove: (element) ->
      $el = $(element)
      if $el
        $el.addClass 'removed'
        setTimeout(() ->
          $el.removeClass 'removed'
          $el.fadeIn()
          $el.remove()
        ,1000)

    removeFromGeoJSON: (geojson) ->
      if geojson.properties?
        $element = @$menu.find("div[data-internal-id='#{geojson.properties.internal_id}']")
        @remove($element)

    _destroy: ->
      @$accordion.remove()

    _resize: ->
      if @options.box?
        if @options.box.height?
          @$accordion.height @options.box.height
        if @options.box.width?
          @$accordion.width @options.box.width
        @_trigger "resize"



  $(document).ready ->
    $("input[data-accordion]").each ->
      $(this).mapeditoraccordion()

) jQuery
