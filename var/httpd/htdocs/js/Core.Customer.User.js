// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Customer = Core.Customer || {};

/**
 * @namespace Core.Customer.User
 * @memberof Core.Customer
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for the CustomerUser module.
 */
 Core.Customer.User = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Customer.User
     * @function
     * @description
     *      This function initializes actions for customer update.
     */
    TargetNS.Init = function() {

        var Customer = Core.Config.Get('Customer');
        var Nav      = Core.Config.Get('Nav');

        // update customer only when parameter Nav is 'None'
        if (!Nav || Nav != 'None') {
            return;
        }

        // call UpdateCustomer function with customer from config if exists
        if (Customer) {
            Core.Agent.TicketAction.UpdateCustomer(Core.Language.Translate(Customer));
        }

        // call UpdateCustomer function with field text parameter
        $('#CustomerTable a').click(function () {
            Core.Agent.TicketAction.UpdateCustomer($(this).text());
        });

    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Customer.User || {}));
