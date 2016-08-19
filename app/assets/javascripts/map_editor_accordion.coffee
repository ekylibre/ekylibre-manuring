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


     simple_data_template: (data) ->
       html = "<div class='accordion-data'>#{group_element_key}"
       for element_key of data
         html += "<div class='item-data'>"
         html += "<div class='item-data-label'>#{element_key}}</div>"
         html += "<div class='item-data-value'>#{data[group_element_key][element_key]}}</div>"
         html += "</div>"
       html += "</div>"

     group_data_template: (data) ->
      html ="<div class='accordion-data'>"
      for group_element_key of data
        html += "<div class='accordion-data-group'>#{group_element_key}"
        for element_key of data[group_element_key]
          element = data[group_element_key][element_key]
          if element
            html += "<div class='item-data'>"
            html += "<div class='item-data-label'>#{element_key}</div>"
            if element.value
                html += "<div class='item-data-value'>#{element.value}</div>"
            else if typeof element == 'object' and !element.value
              html += "<div class='sub-item-data-group'>"
              for sub_element_key of element
                html += "<div class='sub-item-data'>"
                html += "<div class='item-data-label'>#{sub_element_key}</div>"
                html += "<div class='item-data-value'>#{element[sub_element_key].value}</div>"
                if element.unit
                  html += "<div class='item-data-unit'>#{element.unit}</div>"
                html += "</div>"
              html += "</div>"
            if element.unit
              html += "<div class='item-data-unit'>#{element.unit}</div>"
          else
            html += "<div class='item-data-value'>#{element}</div>"

          html += "</div>"
      html += "</div>"
      return html

    template: (properties) ->

      html = "<div class='item' data-internal-id='#{properties.internal_id}'>"
      html += "<div class='actions'>"
      if @options.button
        html += "<button type='button' class='item_button'></button>"
      html += "</div>"
      html += "<div class='item-label'>#{properties.name || properties.id}</div>"

      if @options.data_group
        html += @group_data_template(properties[@options.data_path])
      if @options.data_simple
        html += @simple_data_template(properties[@options.data_path])

        
      html += "</div>"
      $(html)

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
