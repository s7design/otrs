// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};

/**
 * @namespace Core.Warn
 * @memberof Core
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for Warning, Error and NoPermission screens.
 */
Core.Warn = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Warn
     * @function
     * @description
     *      This function bind on click event.
     */
    TargetNS.Init = function () {

        $('#GoBack').on('click', function () {

            // check if an older history entry is available
            if (history.length > 1) {
            history.back();
            return false;
            }

            // if we're in a popup window, close it
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
}(Core.Warn || {}));
