(($) ->
  "use strict"

  $(document).ready ->
    $el = $('input.manuring_result_form[data-map-editor]')

    $('#intervention_submit_button').prop( "disabled", true )

    $('#intervention_submit_button').on 'click', (e) ->
      e.preventDefault();
      manure_zone_ids = []
      $('input.manure_selected_icon:checkbox:checked').each (index, elem) =>
        manure_zone_ids.push($(elem).attr('id'))
      $('#manure_zone_ids_input').val(manure_zone_ids)
      $("#new_manure_management_plan_intervention").submit();

    $('#new_manure_management_plan_intervention').on 'ajax:error', (event, xhr, status, error) ->
      console.log(error)

    $('#new_manure_management_plan_intervention').on 'ajax:success', (event, xhr, status, data) ->
      $el.trigger('manure_intervention_menu:intervention_added', data.responseJSON.results)

) jQuery
