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
 * @namespace Core.Customer.NavigationBar
 * @memberof Core.Customer
 * @author OTRS AG
 * @description
 *      This namespace contains special functions for NavigationBar module.
 */
Core.Customer.NavigationBar = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Customer.NavigationBar
     * @function
     * @description
     *      This function initializes CustomerNavigationBar functionality.
     */
    TargetNS.Init = function() {

        window.setInterval(function() {

            var Data = {
                Action: 'CustomerChat',
                Subaction: 'ChatGetOpenRequests'
            };

            Core.AJAX.FunctionCall(
                Core.Config.Get('Baselink'),
                Data,
                function(Response) {
                    if (!Response || parseInt(Response, 10) < 1) {
                        $('.Individual .ChatRequests').fadeOut(function() {
                            $(this).addClass('Hidden');
                        });
                    }
                    else {
                        $('.Individual .ChatRequests')
                            .fadeIn(function() {
                                $(this).removeClass('Hidden');
                            })
                            .find('.Counter')
                            .text(Response);

                        // show tooltip to get the users attention
                        if (!$('.Individual .ChatRequests .ChatTooltip').length) {
                            $('.Individual .ChatRequests')
                                .append('<span class="ChatTooltip">' + Core.Language.Translate("You have unanswered chat requests") + '</span>')
                                .find('.ChatTooltip')
                                .bind('click', function(Event) {
                                    $(this).fadeOut();
                                    Event.stopPropagation();
                                    return false;
                                })
                                .fadeIn();
                        }
                    }
                },
                'json'
            );

        }, 60000);
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;

}(Core.Customer.NavigationBar || {}));
