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
 * @namespace Core.Agent.Admin.Group
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for AdminGroup.
 */
Core.Agent.Admin.Group = (function (TargetNS) {

    /**
     * @name Init
     * @memberof CCore.Agent.Admin.Group
     * @function
     * @description
     *      This function initializes the special module functions
     */
    TargetNS.Init = function () {
        $('#Submit').bind('click', TargetNS.AdminGroupCheck);
        Core.UI.Table.InitTableFilter($('#FilterGroups'), $('#Groups'));
    };

    /**
     * @name AdminGroupCheck
     * @memberof Core.Agent.Admin.Group
     * @function
     * @returns {Boolean} returns true.
     * @description
     *      This function checks a group with special name 'admin'
     */
    TargetNS.AdminGroupCheck = function () {
        var NameValue = $('#GroupName').val(),
            NameOldValue = $('#GroupOldName').val();

        if (!NameOldValue || NameOldValue !== 'admin' || NameValue === 'admin') {
            return true;
        }

        if (confirm(Core.Language.Translate("WARNING: When you change the name of the group 'admin', before making the appropriate changes in the SysConfig, you will be locked out of the administrations panel! If this happens, please rename the group back to admin per SQL statement."))) {
            return true;
        }
        else {
            $('#GroupName').focus();
            return false;
        }
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.Group || {}));
