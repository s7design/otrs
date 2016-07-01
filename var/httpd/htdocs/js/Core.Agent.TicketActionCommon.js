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
 * @namespace Core.Agent.TicketActionCommon
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains special module functions for AgentTicketActionCommon.
 */
Core.Agent.TicketActionCommon = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.TicketActionCommon
     * @function
     * @description
     *      This function initializes the module functionality.
     */
    TargetNS.Init = function () {

        var $Form,
            FieldID,
            Index,
            TypeFieldUpdate,
            QueueFieldUpdate,
            ServiceFieldUpdate,
            SLAFieldUpdate,
            OwnerFieldUpdate,
            ResponsibleFieldUpdate,
            StateFieldUpdate,
            PriorityFieldUpdate,
            DynamicFieldNames = Core.Config.Get('DynamicFieldNames');

        // Bind event to Type field.
        $('#TypeID').on('change', function () {
            TypeFieldUpdate = ['ServiceID', 'SLAID', 'NewOwnerID', 'NewResponsibleID', 'NewStateID', 'NewPriorityID'];
            for (Index in DynamicFieldNames) {
                TypeFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'TypeID', TypeFieldUpdate);
        });

        // Bind event to Queue field.
        $('#NewQueueID').on('change', function () {
            QueueFieldUpdate = ['TypeID', 'ServiceID', 'NewOwnerID', 'NewResponsibleID', 'NewStateID', 'NewPriorityID', 'StandardTemplateID'];
            for (Index in DynamicFieldNames) {
                QueueFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'NewQueueID', QueueFieldUpdate);
        });

        // Bind event to Service field.
        $('#ServiceID').on('change', function () {
            ServiceFieldUpdate = ['TypeID', 'SLAID', 'NewOwnerID', 'NewResponsibleID', 'NewStateID', 'NewPriorityID'];
            for (Index in DynamicFieldNames) {
                ServiceFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'ServiceID', ServiceFieldUpdate);
        });

        // Bind event to SLA field.
        $('#SLAID').on('change', function () {
            SLAFieldUpdate = ['TypeID', 'ServiceID', 'NewOwnerID', 'NewResponsibleID', 'NewStateID', 'NewPriorityID'];
            for (Index in DynamicFieldNames) {
                SLAFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'SLAID', SLAFieldUpdate);
        });

        // Bind event to Owner field.
        $('#NewOwnerID').on('change', function () {
            OwnerFieldUpdate = ['TypeID', 'ServiceID', 'SLAID', 'NewResponsibleID', 'NewStateID', 'NewPriorityID'];
            for (Index in DynamicFieldNames) {
                OwnerFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'NewOwnerID', OwnerFieldUpdate);
        });

        // Bind event to Responsible field.
        $('#NewResponsibleID').on('change', function () {
            ResponsibleFieldUpdate = ['TypeID', 'ServiceID', 'SLAID', 'NewOwnerID', 'NewStateID', 'NewPriorityID'];
            for (Index in DynamicFieldNames) {
                ResponsibleFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'NewResponsibleID', ResponsibleFieldUpdate);
        });

        // Bind event to State field.
        $('#NewStateID').on('change', function () {
            StateFieldUpdate = ['TypeID', 'ServiceID', 'SLAID', 'NewOwnerID', 'NewResponsibleID', 'NewPriorityID'];
            for (Index in DynamicFieldNames) {
                StateFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'NewStateID', StateFieldUpdate);
        });

        // Bind event to State field.
        $('#NewPriorityID').on('change', function () {
            PriorityFieldUpdate = ['TypeID', 'ServiceID', 'SLAID', 'NewOwnerID', 'NewResponsibleID', 'NewStateID'];
            for (Index in DynamicFieldNames) {
                PriorityFieldUpdate.push(DynamicFieldNames[Index]);
            }

            Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'NewPriorityID', PriorityFieldUpdate);
        });

        // Bind event to StandardTemplate field.
        $('#StandardTemplateID').bind('change', function () {
            Core.Agent.TicketAction.ConfirmTemplateOverwrite('RichText', $(this), function () {
                Core.AJAX.FormUpdate($('#Compose'), 'AJAXUpdate', 'StandardTemplateID', ['RichTextField']);
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
}(Core.Agent.TicketActionCommon || {}));
