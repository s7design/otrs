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
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.CloudServices
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for CloudServices module.
 */
 Core.Agent.Admin.CloudServices = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.Admin.CloudServices
     * @function
     * @description
     *      This function initializes module functionality.
     */
    TargetNS.Init = function () {
        $('#GoBack').on('click', function () {

            // check if an older history entry is available
            if (history.length > 1) {
                history.back();
                return false;
            }

            // if we are in a popup window, close it
            if (Core.UI.Popup.CurrentIsPopupWindow()) {
                Core.UI.Popup.ClosePopup();
                return false;
            }

            // normal window, no history: no action possible
            return false;
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
 }(Core.Agent.Admin.CloudServices || {}));
