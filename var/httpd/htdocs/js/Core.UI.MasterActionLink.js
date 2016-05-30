// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.UI = Core.UI || {};

/**
 * @namespace Core.UI.MasterActionLink
 * @memberof Core.UI
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for the MasterActionLink module.
 */
 Core.UI.MasterActionLink = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.UI.MasterActionLink
     * @function
     * @description
     *      This function initializes click event in the table row class 'MasterAction'.
     */
     TargetNS.Init = function () {

        $('.MasterAction').bind('click', function (Event) {
            var $MasterActionLink = $(this).find('.MasterActionLink');

            // only act if the link was not clicked directly
            if (Event.target !== $MasterActionLink.get(0)) {
                window.location = $MasterActionLink.attr('href');
                return false;
            }
        });
     };

     Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.UI.MasterActionLink || {}));
