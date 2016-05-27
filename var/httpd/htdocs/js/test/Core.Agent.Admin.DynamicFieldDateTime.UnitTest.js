// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};

Core.Agent.Admin.DynamicFieldDateTime = (function (Namespace) {
    Namespace.RunUnitTests = function(){
        var $TestForm = $('<fieldset id="TestForm" class="TableLike"'
            + '<div class="Field">'
            + '<label for="YearsPeriod">Define years period:</label>'
            + '<select class="Modernize W50pc" id="YearsPeriod" name="YearsPeriod">'
            + '<option value="0" selected="selected">No</option>'
            + '<option value="1">Yes</option>'
            + '</select></div>'

            + '<fieldset id="YearsPeriodOption" class="TableLike Hidden">'
            + '<label for="YearsInPast">Years in the past:</label>'
            + '<div class="Field">'
            + '<input id="YearsInPast" class="W50pc Validate_PositiveNegativeNumbers" type="text" maxlength="200" value="" name="YearsInPast"/>'
            + '</div>'

            + '<label for="YearsInFuture">Years in the future:</label>'
            + '<div class="Field">'
            + '<input id="YearsInFuture" class="W50pc Validate_PositiveNegativeNumbers" type="text" maxlength="200" value="" name="YearsInFuture"/>'
                + '</div></fieldset></fieldset>');

        $('body').append($TestForm);

        // add click event
        $('#YearsPeriod').bind('change', function () {
            Core.Agent.Admin.DynamicFieldDateTime.ToogleYearsPeriod($(this).val());
        });

        test('Core.Agent.Admin.DynamicFieldDateTime', function(){

            expect(3);

            // verify 'Years in past' and 'Years in future' fields are hidden
            equal($('#YearsPeriodOption').hasClass("Hidden"), true, 'Fields are hidden');

            // select 'Yes' for define Years Period
            $('#YearsPeriod').val('1').trigger('redraw.InputField').trigger('change');

            // verify 'Years in past' and 'Years in future' fields are shown
            equal($('#YearsPeriodOption').hasClass("Hidden"), false, 'Fields are shown');

            // select 'No' for define Years Period
            $('#YearsPeriod').val('0').trigger('redraw.InputField').trigger('change');

            // verify 'Years in past' and 'Years in future' fields are hidden again
            equal($('#YearsPeriodOption').hasClass("Hidden"), true, 'Fields are hidden');

            // cleanup content
            $('#TestForm').remove();
        });
    };

    return Namespace;
}(Core.Agent.Admin.DynamicFieldDateTime || {}));
