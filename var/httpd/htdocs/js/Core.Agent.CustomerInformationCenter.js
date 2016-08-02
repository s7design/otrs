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

/**
 * @namespace Core.Agent.CustomerInformationCenter
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for CustomerInformationCenter.
 */
Core.Agent.CustomerInformationCenter = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.CustomerInformationCenter
     * @function
     * @description
     *      This function initialize module functionality.
     */
    TargetNS.Init = function () {
        var CustomerUserRefresh = Core.Config.Get('CustomerUserListRefresh');

        // Binds event for opening search dialog
        $('#CustomerInformationCenterHeading').on('click', function() {
            Core.Agent.CustomerInformationCenterSearch.OpenSearchDialog();
            return false;
        });

        // Bind event on create chat request button
        $('a.CreateChatRequest').bind('click', function() {
            var $Dialog = $('#DashboardUserOnlineChatStartDialog').clone();

            $Dialog.find('input[name=ChatStartUserID]').val($(this).data('user-id'));
            $Dialog.find('input[name=ChatStartUserType]').val($(this).data('user-type'));
            $Dialog.find('input[name=ChatStartUserFullname]').val($(this).data('user-fullname'));

            Core.UI.Dialog.ShowContentDialog($Dialog.html(), Core.Language.Translate('Start chat'), '100px', 'Center', true);

            // Only enable button if there is a message
            $('.Dialog textarea[name="ChatStartFirstMessage"]').on('keyup', function(){
                $('.Dialog button').prop('disabled', $(this).val().length ? false : true);
            });

            $('.Dialog form').on('submit', function(){
                if (!$('.Dialog textarea[name=ChatStartFirstMessage]').val().length) {
                    return false;
                }
                // Close after submit
                window.setTimeout(function(){
                    Core.UI.Dialog.CloseDialog($('.Dialog'));
                }, 1);
            });

            return false;
        });

        if (typeof CustomerUserRefresh !== 'undefined') {
            Core.Config.Set('RefreshSeconds_' + CustomerUserRefresh.NameHTML, parseInt(CustomerUserRefresh.RefreshTime, 10) || 0);
            if (Core.Config.Get('RefreshSeconds_' + CustomerUserRefresh.NameHTML)) {
                Core.Config.Set('Timer_' + CustomerUserRefresh.NameHTML, window.setTimeout(function() {

                    // get active filter
                    var Filter = $('#Dashboard' + Core.App.EscapeSelector(CustomerUserRefresh.Name) + '-box').find('.Tab.Actions li.Selected a').attr('data-filter');
                    $('#Dashboard' + Core.App.EscapeSelector(CustomerUserRefresh.Name) + '-box').addClass('Loading');
                    Core.AJAX.ContentUpdate($('#Dashboard' + Core.App.EscapeSelector(CustomerUserRefresh.Name)), Core.Config.Get('Baselink') + 'Action=' + Core.Config.Get('Action') + ';Subaction=Element;Name=' + CustomerUserRefresh.Name + ';Filter=' + Filter + ';CustomerID=' + CustomerUserRefresh.CustomerID, function () {
                        $('#Dashboard' + Core.App.EscapeSelector(CustomerUserRefresh.Name) + '-box').removeClass('Loading');
                    });
                    clearTimeout(Core.Config.Get('Timer_' + CustomerUserRefresh.NameHTML));
                }, Core.Config.Get('RefreshSeconds_' + CustomerUserRefresh.NameHTML) * 1000));
            }
        }
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.CustomerInformationCenter || {}));
