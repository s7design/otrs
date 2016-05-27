// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};

Core.Agent.Admin.DynamicFieldText = (function (Namespace) {
    Namespace.RunUnitTests = function(){
        var $TestForm = $('<fieldset id="TestForm" class="TableLike">'
            + '<div class="Field RegExInsert">'
            + '<input name="RegExCounter" value="" id="RegExCounter" class="RegExCounter Hidden"/>'

            + '<fieldset class="RegExTemplate Hidden TableLike SpacingTop">'
            + '<label class="Mandatory W50pc" for="RegEx">RegEx</label>'

            + '<div class="Field">'
            + '<input id="RegEx" class="W80pc" type="text" maxlength="500" value="" name="RegEx"/>'
            + '<div id="RegExError" class="TooltipErrorMessage"><p>"This field is required."</p></div>'
            + '<div id="RegExServerError" class="TooltipErrorMessage"></div>'
            + '</div>'

            + '<label class="Mandatory" for="CustomerRegExErrorMessage">Error Message</label>'
            + '<div class="Field">'
            + '<input id="CustomerRegExErrorMessage" class="W80pc" type="text" maxlength="500" value="" name="CustomerRegExErrorMessage"/>'
            + '<div id="CustomerRegExErrorMessageError" class="TooltipErrorMessage"><p>"This field is required."</p></div>'
            + '<div id="CustomerRegExErrorMessageServerError" class="TooltipErrorMessage"></div>'

            + '<button id="RemoveRegEx" class="RemoveRegEx"><span>Remove</span></button>'
            + '</div>'
            + '</fieldset>'

            + '<label for="AddRegEx">Add RegEx</label>'
            + '<div class="Field">'
            + '<button id="AddRegEx"><span>Add</span></button>'
            + '</div>'
            + '</fieldset>');

        $('body').append($TestForm);

        // add click event
        $('#AddRegEx').bind('click', function () {
            Core.Agent.Admin.DynamicFieldText.AddRegEx(
                $(this).closest('fieldset').find('.RegExInsert')
            );
        });

        test('Core.Agent.Admin.DynamicFieldText', function(){
            var RegExAddButton = $('#AddRegEx'),
                RegExInputField,
                RegExErrorField,
                RegExRemoveButton,
                Count = 0;

            expect(10);

            // check for 'Add' button
            ok(RegExAddButton, 'Found RegEx add button');

            // click on 'Add' button
            RegExAddButton.trigger('click');
            Count++;

            // define variable for added RegEx
            RegExInputField = $('#RegEx_' + Count).length;
            RegExErrorField = $('#CustomerRegExErrorMessage_' + Count).length;
            RegExRemoveButton = $('#RemoveRegEx_' + Count);

            // verify there is RegEx fields and remove button
            ok(RegExInputField, 'Found RegEx input field');
            ok(RegExErrorField, 'Found RegEx error field');
            ok(RegExRemoveButton, 'Found RegEx remove button');

            // click on 'Remove' button
            RegExRemoveButton.trigger('click');

            RegExInputField = $('#RegEx_' + Count).length;
            RegExErrorField = $('#CustomerRegExErrorMessage_' + Count).length;
            RegExRemoveButton = $('#RemoveRegEx_' + Count).lenght;

            // verify there is no more RegEx fields and remove button
            /*eslint-disable no-undef*/
            notOk(RegExInputField, 'Not Found RegEx input field');
            notOk(RegExErrorField, 'Not Found RegEx error field');
            notOk(RegExRemoveButton, 'Not Found RegEx remove button');
            /*eslint-enable no-undef*/

            // click to add another RegEx field
            RegExAddButton.trigger('click');
            Count++;

            // verify ID increment
            RegExInputField = $('#RegEx_' + Count).length;
            RegExErrorField = $('#CustomerRegExErrorMessage_' + Count).length;
            RegExRemoveButton = $('#RemoveRegEx_' + Count);

            ok(RegExInputField, 'ID increment correct for RegEx input field');
            ok(RegExErrorField, 'ID increment correct for RegEx error field');
            ok(RegExRemoveButton, 'ID increment correct for RegEx remove button');

            // cleanup content
            $('#TestForm').remove();
        });
    };

    return Namespace;
}(Core.Agent.Admin.DynamicFieldText || {}));
