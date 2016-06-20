// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace Core.Agent.TicketLinkObject
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for the LinkObject screen.
 */
Core.Agent.TicketLinkObject = (function (TargetNS) {
    /**
     * @name Init
     * @memberof Core.Agent.TicketLinkObject
     * @function
     * @description
     *      This function initializes the LinkObject screen.
     */
    TargetNS.Init = function () {

        var SearchValueFlag;

        $('#LinkAddCloseLink, #LinkDeleteCloseLink').on('click', function () {
            Core.UI.Popup.ClosePopup();
            return false;
        });

        $('#TargetIdentifier').on('change', function () {
            $('#SubmitSelect').addClass('gotclicked');
            $(this).closest('form').submit();
        });
        // Two submits in this form
        // if SubmitSelect or AddLinks button was clicked,
        // add "gotclicked" class to this button
        $('#SubmitSelect, #AddLinks').on('click.Submit', function () {
           $('#SubmitSelect').addClass('gotclicked');
        });

        $('#LinkSearchForm').submit(function () {
            // If SubmitSelect button was clicked,
            // "gotclicked" was added as class to the button
            // remove the class and do the search
            if ($('#SubmitSelect').hasClass('gotclicked')) {
                $('#SubmitSelect').removeClass('gotclicked');
                return true;
            }

            SearchValueFlag = false;
            $('#LinkSearchForm input, #LinkSearchForm select').each(function () {
                if ($(this).attr('name') && $(this).attr('name').match(/^SEARCH\:\:/)) {
                    if ($(this).val() && $(this).val() !== '') {
                        SearchValueFlag = true;
                    }
                }
            });

            if (!SearchValueFlag) {
               alert(Core.Language.Translate("Please enter at least one search value or * to find anything."));
               return false;
            }
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.TicketLinkObject || {}));
