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
 * @namespace Core.Agent.Admin.Checkbox
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for checkbox selection.
 */
 Core.Agent.Admin.Checkbox = (function (TargetNS) {

    /*
    * @name InitSelectAllCheckboxes
    * @memberof Core.Agent.Admin.Checkbox
    * @function
    * @description
    *      This function initializes "SelectAll" checkbox and bind click event on "SelectAll" for each relation item
    */
    TargetNS.InitSelectAllCheckboxes = function () {
        var RelationItems = Core.Config.Get('RelationItems');

        $.each(RelationItems, function (index) {
            Core.Form.InitSelectAllCheckboxes($('table td input[type="checkbox"][name=' + RelationItems[index] + ']'), $('#SelectAll' + RelationItems[index]));

            $('input[type="checkbox"][name=' + RelationItems[index] + ']').bind('click', function () {
                Core.Form.SelectAllCheckboxes($(this), $('#SelectAll' + RelationItems[index]));
            });
        });
    };

    return TargetNS;
}(Core.Agent.Admin.Checkbox || {}));
