// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.ProcessManagement = Core.ProcessManagement || {};

/**
 * @namespace Core.ProcessManagement.ActivityDialog
 * @memberof Core.ProcessManagement
 * @author OTRS AG
 * @description
 *      This namespace contains the special function for ActivityDialog module.
 */
 Core.ProcessManagement.ActivityDialog = (function (TargetNS) {

    /*
    * @name Init
    * @memberof Core.ProcessManagement.ActivityDialog
    * @function
    * @description
    *      This function initializes ActivityDialog in Ticketprocess screen.
    */
    TargetNS.Init = function () {
        if(Core.Config.Get('ParentReload') && Core.Config.Get('ParentReload') == 1){
            Core.UI.Popup.FirePopupEvent('Reload');
        }
        Core.Form.Validate.Init();

        // Register event for tree selection dialog
        Core.UI.TreeSelection.InitTreeSelection();
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.ProcessManagement.ActivityDialog || {}));
