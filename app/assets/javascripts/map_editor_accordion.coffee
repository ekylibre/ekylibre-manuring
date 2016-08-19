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

      widget.element.trigger "accordion:loaded"

    template: (properties) ->
      html = "<div class='item' data-internal-id='#{properties.internal_id}'>"
      html += "<div class='actions'>"

      if @options.storageZones?
        html += "<select data-action='change_storage_zone_container'>"
        html += '<option></option>'


        for zone in @options.storageZones
          selected = ""

          if zone.internal_id == parseInt(properties.storage_zone_container)
            selected = "selected"

          level = ''

          unless isNaN(zone.level)
            level = " (#{zone.level})"

          html += "<option value='#{zone.internal_id}' #{selected}>#{zone.name}#{level}</option>"

        html += "</select>"

      if @options.multiLevels?
        html += "<select data-action='change_level'>"
        html += '<option></option>'

        for level in [parseInt(@options.multiLevels.maxLevel)..parseInt(@options.multiLevels.minLevel)]
          selected = ""

          if level == parseInt(properties.level)
            selected = "selected"

          if level == 0
            label = 'RDC' #TODO i18n this
          else
            label = "#{@options.multiLevels.levelLabel} #{level}"

          html += "<option value='#{level}' #{selected}>#{label}</option>"

        html += "</select>"

      if @options.button
        html += "<button type='button' class='item_button'></button>"


      if properties.removable? and properties.removable == true
        html += "<button class='close' data-action='delete'></button>"

      html += "</div>"
      html += "<div class='item-label'>#{properties.name || properties.id}</div>"
      html += "</div>"
      $(html)

    insert: (geojson) ->
      if geojson.properties?

        $render = @template(geojson.properties)
        @$menu.append $render

        $render.on 'click', (e) =>
          $(@element).trigger('mapeditoractionmenu:feature_select',e.currentTarget)

        $render.on 'click', '*[data-action="delete"]', (e) =>
          e.preventDefault()
          feature = $(e.currentTarget).closest('*[data-internal-id]')
          $(@element).trigger('mapeditoractionmenu:feature_remove',feature)
          false

        $render.on 'change', '*[data-action="change_level"]', (e) =>
          e.preventDefault()
          feature = $(e.currentTarget).closest('*[data-internal-id]')
          level = $(e.currentTarget).val()
          type = 'level'
          $(@element).trigger('mapeditoractionmenu:feature_update',[feature,level,type])
          false

        $render.on 'change', '*[data-action="change_storage_zone_container"]', (e) =>
          e.preventDefault()
          feature = $(e.currentTarget).closest('*[data-internal-id]')
          storage_zone_container = $(e.currentTarget).val()
          type = 'storage zone container'
          $(@element).trigger('mapeditoractionmenu:feature_update',[feature,storage_zone_container,type])
          false

    update: (geojson) ->
      if geojson.properties?
        $element = @$menu.find("div[data-internal-id='#{geojson.properties.internal_id}']")
        if $element
          $render = @template(geojson.properties)
          $element.html($render.html())

          $element.addClass 'updated'
          setTimeout(() ->
            $element.removeClass 'updated'
          ,1000)

    apply: (internal_id,fun) ->
      $element = @$menu.find("div[data-internal-id='#{internal_id}']")
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
