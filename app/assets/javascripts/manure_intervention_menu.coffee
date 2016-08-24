(($) ->
  "use strict"

  $.widget "ui.manureinterventionmenu",
    options:
      box:
        height: null
        width: null
      customClass: ''

    _create: ->
      $.extend(true, @options, @element.data("intervention-menu"))

      @$intervention_menu= $('<div>', class: "intervention_menu #{this.options.customClass}").insertAfter(@element)
      widget = this

      @_resize()

      widget.element.trigger "intervention_menu:loaded"

    insert: (feature) ->
      
      
    update: (geojson) ->

    apply: (internal_id,fun) ->
      $element = @$intervention_menu.find("div[data-internal-id='#{internal_id}']")
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

    _destroy: ->
      @$intervention_menu.remove()

    _resize: ->
      if @options.box?
        if @options.box.height?
          @$intervention_menu.height @options.box.height
        if @options.box.width?
          @$intervention_menu.width @options.box.width
        @_trigger "resize"



  $(document).ready ->
    $("input[data-intervention-menu]").each ->
      $(this).manureinterventionmenu()
      

) jQuery
