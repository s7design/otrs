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
 * @namespace Core.PreferencesNotificationEvent
 * @memberof Core
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for the Preferences notification events.
 */
Core.PreferencesNotificationEvent = (function (TargetNS) {

        /**
         * @name Init
         * @memberof Core.PreferencesNotificationEvent
         * @function
         * @description
         *      This function initializes the module functionality.
         */
        TargetNS.Init = function () {

            // make sure user has chosen at least one transport for mandatory notifications
            $('tr.Mandatory .NotificationEvent').closest('form').off().on('submit', function(Event) {
                $(this).find('tr.Mandatory').each(function() {
                    var FoundEnabled = false;
                    $(this).find('.NotificationEvent').each(function() {
                        if ($(this).prop('checked')) {
                            FoundEnabled = true;
                        }
                    });

                    // if there is not at least one transport enabled, omit the actions
                    if (!FoundEnabled) {
                        alert(Core.Language.Translate("Sorry, but you can't disable all methods for notifications marked as mandatory."));
                        Event.preventDefault();
                        Event.stopPropagation();
                        return false;
                    }
                });
            });

            $('.NotificationEvent').on('click', function(Event){
                var FoundEnabled = false,
                    $TargetObj = $(this).parent().find('input[type=hidden]');

                // if the user is trying to disable this transport, go through all transport checkboxes
                // for this notification and check if at least one of them is checked
                if (!$(this).prop('checked') && $(this).closest('tr').hasClass('Mandatory')) {

                    $(this).closest('tr.Mandatory').find('.NotificationEvent').each(function() {
                        if ($(this).prop('checked')) {
                            FoundEnabled = true;
                            return true;
                        }
                    });

                    // if there is not at least one transport enabled, omit the actions
                    if (!FoundEnabled) {
                        alert(Core.Language.Translate("Sorry, but you can't disable all methods for this notification."));
                        Event.stopPropagation();
                        return false;
                    }
                }

                if ($TargetObj.val() == 0){
                    $TargetObj.val(1);
                }
                else{
                    $TargetObj.val(0);
                }
            });
        };

        Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.PreferencesNotificationEvent || {}));
