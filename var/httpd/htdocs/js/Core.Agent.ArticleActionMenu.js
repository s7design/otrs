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
 * @namespace Core.Agent.ArticleActionMenu
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains special module functions for the ArticleActionMenu.
 */
Core.Agent.ArticleActionMenu = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.ArticleActionMenu
     * @function
     * @param {String} FormID - ID of html element where a dropdown element is placed
     * @param {String} Name - Name of the dropdown element for which event is created
     * @description
     *      This function initializes the JS functionality.
     */
    TargetNS.Init = function (FormID, Name) {

        var URL;

        $('#' + FormID + ' select[name=' + Name + ']').on('change', function () {
            if ($(this).val() > 0) {
                URL = Core.Config.Get('Baselink') + $(this).parents().serialize();
                Core.UI.Popup.OpenPopup(URL, 'TicketAction');

                // reset the select box so that it can be used again from the same window
                $(this).val('0');
            }
        });
    };

    return TargetNS;
}(Core.Agent.ArticleActionMenu || {}));
