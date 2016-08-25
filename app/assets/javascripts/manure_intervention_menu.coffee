(($) ->
  "use strict"

  $(document).ready ->
    $el = $('input.manuring_step_form[data-map-editor]')

    $('#intervention_submit_button').prop( "disabled", true )
    
    $('#intervention_submit_button').on 'click', (e) ->
      e.preventDefault();
      manure_zone_ids = []
      $('input.manure_selected_icon:checkbox:checked').each (index, elem) =>
        manure_zone_ids.push($(elem).attr('id'))

      console.log(manure_zone_ids)
      $('#manure_zone_ids_input').val(manure_zone_ids)
      console.log("zone_id " + $('#manure_zone_ids_input').val())
      $("#new_manure_management_plan_intervention").submit();


) jQuery
