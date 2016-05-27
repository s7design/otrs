// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};

Core.Agent.Admin.DynamicFieldMultiselect = (function (Namespace) {
    Namespace.RunUnitTests = function(){
        var $TestForm = $('<fieldset id="TestForm" class="TableLike">'
            + '<div class="Field ValueInsert">'
            + '<input type="hidden" name="ValueCounter" value="" id="ValueCounter" class="ValueCounter"/>'

            + '<label for="DefaultValue">Default value:</label>'
            + '<div class="Field">'
            + '<select class="Modernize W50pc" id="DefaultValue" multiple="multiple" name="DefaultValue">'
            + '<option value="">-</option></select>'

            + '<fieldset class="ValueTemplate Hidden">'
            + '<label for="Key">Key</label>'
            + '<input name="Key" id="Key" class="DefaultValueKeyItem W20pc" type="text" maxlength="100" value=""/>'
            + '<div id="KeyError" class="TooltipErrorMessage"><p>"This field is required."</p></div>'
            + '<div id="KeyServerError" class="TooltipErrorMessage"></div>'
            + '<label for="Value">Value</label>'
            + '<input name="Value" id="Value" class="DefaultValueItem W20pc" type="text" maxlength="100" value=""/>'
            + '<div id="ValueError" class="TooltipErrorMessage"><p>"This field is required."</p></div>'
            + '<div id="ValueServerError" class="TooltipErrorMessage"><p>"This field is required."</p></div>'

            + '<button href="#" id="RemoveValue" class="RemoveButton ValueRemove"><span>Remove value</span></button>'
            + '</fieldset>'

            + '<div class="Field">'
            + '<button href="#" id="AddValue" class="AddButton"><span>Add Value</span></button>'
            + '</div></div></fieldset>');

        $('body').append($TestForm);

        // add click event
        $('#AddValue').bind('click', function () {
            Core.Agent.Admin.DynamicFieldMultiselect.AddValue(
                 $(this).closest('fieldset').find('.ValueInsert')
            );
        });

        test('Core.Agent.Admin.DynamicFieldMultiselect', function(){
            var ValueAddButton = $('#AddValue'),
                ValueFieldKey,
                ValueFieldValue,
                ValueRemoveButton,
                DefaultValue = $('#DefaultValue'),
                DefaultValueOption,
                InputEvent = $.Event('keyup'),
                Count = 0;

            expect(14);

            // check for 'Add Value' button
            ok(ValueAddButton, 'Found "Value" add button');

            // verify Default Value field has no selectable options
            DefaultValueOption = DefaultValue.find('option').not("[value='']").length;
            equal(DefaultValueOption, 0, '"Default Value" field has no selectable options');

            // click on 'Add Value' button
            ValueAddButton.trigger('click');
            Count++;

            // verify JS added Value, Key fields and remove value button
            ValueFieldKey = $('#Key_' + Count).length;
            ValueFieldValue = $('#Value_' + Count).length;
            ValueRemoveButton = $('#RemoveValue_' + Count);

            ok(ValueFieldKey, 'Found "Value 1" key input field');
            ok(ValueFieldValue, 'Found "Value 1" value input field');
            ok(ValueRemoveButton, 'Found "Value 1" remove button');

            // input test data in first Value and Key fields
            $('#Key_1').val('TestKey1').trigger(InputEvent);
            $('#Value_1').val('TestValue1').trigger(InputEvent);

            // verify Default Value field has one selectable option
            DefaultValueOption = DefaultValue.find('option').not("[value='']").length;
            equal(DefaultValueOption, 1, '"Default Value" field has 1 selectable option');

            // click on 'Add Value' button again
            ValueAddButton.trigger('click');
            Count++;

            // verify JS added Value, Key fields and remove value button
            ValueFieldKey = $('#Key_' + Count).length;
            ValueFieldValue = $('#Value_' + Count).length;
            ValueRemoveButton = $('#RemoveValue_' + Count);

            ok(ValueFieldKey, 'Found "Value 2" key input field');
            ok(ValueFieldValue, 'Found "Value 2" value input field');
            ok(ValueRemoveButton, 'Found "Value 2" remove button');

            // input test data in second Value and Key fields
            $('#Key_2').val('TestKey2').trigger(InputEvent);
            $('#Value_2').val('TestValue2').trigger(InputEvent);

            // verify Default Value field has two selectable options
            DefaultValueOption = DefaultValue.find('option').not("[value='']").length;
            equal(DefaultValueOption, 2, '"Default Value" field has 2 selectable options');

            // click to remove second added Value and Key field and verify JS action
            ValueRemoveButton.trigger('click');

            ValueFieldKey = $('#Key_' + Count).length;
            ValueFieldValue = $('#Value_' + Count).length;
            ValueRemoveButton = $('#RemoveValue_' + Count).lenght;

            /*eslint-disable no-undef*/
            notOk(ValueFieldKey, 'Not found "Value 2" key input field');
            notOk(ValueFieldValue, 'Not found "Value 2" value input field');
            notOk(ValueRemoveButton, 'Not found "Value 2" remove button');
            /*eslint-enable no-undef*/

            // verify JS removed selectable option from Default Value field
            DefaultValueOption = DefaultValue.find('option').not("[value='']").length;
            equal(DefaultValueOption, 1, '"Default Value" field has 1 selectable options');

            // cleanup content
            $('#TestForm').remove();
        });
    };

    return Namespace;
}(Core.Agent.Admin.DynamicFieldMultiselect || {}));
