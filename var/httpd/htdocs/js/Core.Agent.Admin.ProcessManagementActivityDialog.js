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
 * @namespace Core.Agent.Admin.ProcessManagementActivityDialog
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for AdminProcessManagementActivityDialog module.
 */
 Core.Agent.Admin.ProcessManagementActivityDialog = (function (TargetNS) {

    /*
    * @name Init
    * @memberof Core.Agent.Admin.ProcessManagementActivityDialog
    * @function
    * @description
    *      This function initializes the special module function.
    */
    TargetNS.Init = function () {

        Core.Agent.Admin.ProcessManagement.InitActivityDialogEdit();
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.ProcessManagementActivityDialog || {}));
