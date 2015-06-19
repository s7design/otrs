// --
// Copyright (C) 2001-2011 OTRS AG, http://otrs.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace Core.Agent.Stats
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for the statistic module.
 */
Core.Agent.Stats = (function (TargetNS) {

    /**
     * @name FormatGraphSizeRelation
     * @memberof Core.Agent.Stats
     * @function
     * @description
     *      Activates the graph size menu if a GD element is selected.
     */
    TargetNS.FormatGraphSizeRelation = function () {
        var $Format = $('#Format'),
            Flag = false,
            Reg = /^GD::/;

        // find out if a GD element is used
        $.each($Format.children('option:selected'), function () {
            if (Reg.test($(this).val()) === true) {
                Flag = true;
            }
        });

        // activate or deactivate the Graphsize menu
        if (Flag) {
            $('#GraphSize').removeAttr('disabled');
        }
        else {
            $('#GraphSize').attr('disabled', 'disabled');
        }
    };

    /**
     * @name SelectCheckbox
     * @memberof Core.Agent.Stats
     * @function
     * @param {String} Name - The name of the radio button to be selected.
     * @description
     *      Activate given checkbox.
     */
    TargetNS.SelectCheckbox = function (Name) {
        $('input[type="checkbox"][name=' + Name + ']').prop('checked', true);
    };

    /**
     * @name SelectRadiobutton
     * @memberof Core.Agent.Stats
     * @function
     * @param {String} Value - The value attribute of the radio button to be selected.
     * @param {String} Name - The name of the radio button to be selected.
     * @description
     *      Selects a radio button by name and value.
     */
    TargetNS.SelectRadiobutton = function (Value, Name) {
        $('input[type="radio"][name=' + Name + '][value=' + Value + ']').prop('checked', true);
    };

        /**
     * @private
     * @name AddSelectClearButton
     * @memberof Core.Agent
     * @function
     * @description
     *      Adds a button next to every select field to clear the selection.
     *      Only select fields with size > 1 are selected (no dropdowns).
     */
    function AddSelectClearButton() {
        var $SelectFields = $('select');

        // Loop over all select fields available on the page
        $SelectFields.each(function () {
            var Size = parseInt($(this).attr('size'), 10),
                $SelectField = $(this),
                SelectID = this.id,
                ButtonHTML = '<a href="#" title="' + TargetNS.Localization.RemoveSelection + '" class="StatsClearSelect" data-select="' + SelectID + '"><span>' + TargetNS.Localization.RemoveSelection + '</span><i class="fa fa-undo"></i></a>';


            // Only handle select fields with a size > 1, leave all single-dropdown fields untouched
            if (isNaN(Size) || Size <= 1) {
                return;
            }

            // If select field has a tree selection icon already,
            // // we want to insert the new code after that element
            if ($SelectField.next('a.ShowTreeSelection').length) {
                $SelectField = $SelectField.next('a.ShowTreeSelection');
            }

            // insert button HTML
            $SelectField.after(ButtonHTML);
        });

        // Bind click event on newly inserted button
        // The name of the corresponding select field is saved in a data attribute
        $('.StatsClearSelect').on('click.ClearSelect', function () {
            var SelectID = $(this).data('select'),
                $SelectField = $('#' + SelectID);

            if (!$SelectField.length) {
                return;
            }

            // Clear field value
            $SelectField.val('');
            $(this).blur();

            return false;
        });
    }

    /**
     * @name Localization
     * @memberof Core.Agent
     * @member {Array}
     * @description
     *     The localization array for translation strings.
     */
    TargetNS.Localization = undefined;

    /**
     * @name Init
     * @memberof Core.Agent
     * @function
     * @param {Object} Params - Initialization and internationalization parameters.
     * @description
     *      This function initialize correctly all other function according to the local language.
     */
    TargetNS.Init = function (Params) {

        TargetNS.Localization = Params.Localization;
        AddSelectClearButton();
    };

    return TargetNS;
}(Core.Agent.Stats || {}));
