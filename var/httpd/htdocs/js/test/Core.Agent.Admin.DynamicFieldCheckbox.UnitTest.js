// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};

Core.Agent.Admin.DynamicFieldCheckbox = (function (Namespace) {
    Namespace.RunUnitTests = function(){
        var $TestForm = $('<fieldset id="TestForm" class="TableLike">'
            + '<label class="Mandatory" for="Name"><span class="Marker">*</span>Name:</label>'
            + '<div class="Field">'
            + '<input id="Name" class="W50pc Validate_Alphanumeric ShowWarning" type="text" maxlength="200" value="" name="Name">'
            + '<p class="FieldExplanation">"Must be unique and only accept alphabetic and numeric characters."</p>'
            + '<p class="Warning Hidden">"Changing this value will require manual changes in the system."</p>'
            + '</div></fieldset>');

        $('body').append($TestForm);

        // add click event
        $('.ShowWarning').bind('change keyup', function () {
            $('p.Warning').removeClass('Hidden');
        });

        test('Core.Agent.Admin.DynamicFieldCheckbox', function(){
            var InputEvent = $.Event('keyup');

            expect(2);

            // verify 'Warning' text is hidden
            equal($('.Warning').hasClass('Hidden'), true, "Warning text is hidden");

            // input 'Name' field
            $('#Name').val('TestName').trigger(InputEvent);

            // verify 'Warning' text is shown
            equal($('.Warning').hasClass('Hidden'), false, "Warning text is shown");

            // cleanup content
            $('#TestForm').remove();
        });
    };

    return Namespace;
}(Core.Agent.Admin.DynamicFieldCheckbox || {}));
