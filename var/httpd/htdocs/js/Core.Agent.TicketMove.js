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
 * @namespace Core.Agent.TicketMove
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains special module functions for AgentTicketMove.
 */
Core.Agent.TicketMove = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.TicketMove
     * @function
     * @description
     *      This function initializes the module functionality.
     */
    TargetNS.Init = function () {

        var $Form,
            FieldID,
            Index,
            QueueFieldUpdate,
            OwnerFieldUpdate,
            StateFieldUpdate,
            PriorityFieldUpdate,
            DynamicFieldNames = Core.Config.Get('DynamicFieldNames');

        // Bind event to Queue field.
        $('#DestQueueID').on('change', function () {
            QueueFieldUpdate = ['NewUserID', 'NewStateID', 'NewPriorityID', 'StandardTemplateID'];
            for (Index in DynamicFieldNames) {
                QueueFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#MoveTicketToQueue'), 'AJAXUpdate', 'DestQueueID', QueueFieldUpdate);
        });

        // Bind event to Owner get all button
        $('#OwnerSelectionGetAll').on('click', function () {
            $('#OwnerAll').val('1');
            Core.AJAX.FormUpdate($('#MoveTicketToQueue'), 'AJAXUpdate', 'OwnerAll', ['NewUserID'], function() {
                $('#NewUserID').focus();
            });
            return false;
        });

        // Bind event to Owner field.
        $('#NewUserID').on('change', function () {
            OwnerFieldUpdate = ['DestQueueID', 'NewStateID', 'NewPriorityID'];
            for (Index in DynamicFieldNames) {
                OwnerFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#MoveTicketToQueue'), 'AJAXUpdate', 'NewUserID', OwnerFieldUpdate);
        });

        // Bind event to State field.
        $('#NewStateID').on('change', function () {
            StateFieldUpdate = ['DestQueueID', 'NewUserID', 'NewPriorityID'];
            for (Index in DynamicFieldNames) {
                StateFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#MoveTicketToQueue'), 'AJAXUpdate', 'NewStateID', StateFieldUpdate);
        });

        // Bind event to Priority field
        $('#NewPriorityID').on('change', function () {
            PriorityFieldUpdate = ['DestQueueID', 'NewUserID', 'NewStateID'];
            for (Index in DynamicFieldNames) {
                PriorityFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#MoveTicketToQueue'), 'AJAXUpdate', 'NewPriorityID', PriorityFieldUpdate);
        });

        // Bind event to StandardTemplate field
        $('#StandardTemplateID').on('change', function () {
            Core.Agent.TicketAction.ConfirmTemplateOverwrite('RichText', $(this), function () {
                Core.AJAX.FormUpdate($('#MoveTicketToQueue'), 'AJAXUpdate', 'StandardTemplateID', ['RichTextField']);
            });
            return false;
        });

        // Bind event to AttachmentDelete button.
        $('button[id*=AttachmentDeleteButton]').on('click', function () {
            $Form = $(this).closest('form');
            FieldID = $(this).attr('id').split('AttachmentDeleteButton')[1];
            $('#AttachmentDelete' + FieldID).val(1);
            Core.Form.Validate.DisableValidation($Form);
            $Form.trigger('submit');
        });

        // Bind event to FileUpload button.
        $('#FileUpload').on('change', function () {
            $Form = $('#FileUpload').closest('form');
            Core.Form.Validate.DisableValidation($Form);
            $Form.find('#AttachmentUpload').val('1').end().submit();
        });

        // Initialize the ticket action popup.
        Core.Agent.TicketAction.Init();
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.TicketMove || {}));
