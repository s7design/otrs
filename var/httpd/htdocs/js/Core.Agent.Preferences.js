// --
// Copyright (C) 2003-2013 OTRS AG, http://otrs.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace Core.Agent.Preferences
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for the GenericInterface job module.
 */
Core.Agent.Preferences = (function (TargetNS) {

    /**
     * @private
     * @name AddSelectClearButton
     * @memberof Core.Agent.Preferences
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
                ButtonHTML = '<a href="#" title="' + TargetNS.Localization.RemoveSelection + '" class="PreferencesClearSelect" data-select="' + SelectID + '"><span>' + TargetNS.Localization.RemoveSelection + '</span><i class="fa fa-undo"></i></a>';


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
        $('.PreferencesClearSelect').on('click.ClearSelect', function () {
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
     * @memberof Core.Agent.Preferences
     * @member {Array}
     * @description
     *     The localization array for translation strings.
     */
    TargetNS.Localization = undefined;

    /**
     * @name Init
     * @memberof Core.Agent.Preferences
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
}(Core.Agent.Preferences || {}));
