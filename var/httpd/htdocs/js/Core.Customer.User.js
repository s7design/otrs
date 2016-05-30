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
     * @name UpdateCustomer
     * @memberof Core.Customer.User
     * @function
     * @description
     *      This function call UpdateCustomer function with customer from config
     */
    TargetNS.UpdateCustomer = function () {
        var Customer = Core.Config.Get('Customer');
        Core.Agent.TicketAction.UpdateCustomer(Core.Language.Translate(Customer));
    };

    /**
     * @name UpdateCustomerText
     * @memberof Core.Customer.User
     * @function
     * @description
     *      This function call UpdateCustomer function with field text parameter
     */
    TargetNS.UpdateCustomerText = function () {
        $('#CustomerTable a').bind('click', function () {
            Core.Agent.TicketAction.UpdateCustomer($(this).text());
        });
    };

    return TargetNS;
}(Core.Customer.User || {}));
