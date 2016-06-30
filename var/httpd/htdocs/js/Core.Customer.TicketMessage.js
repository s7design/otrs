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
 * @namespace Core.Customer.TicketMessage
 * @memberof Core.Customer
 * @author OTRS AG
 * @description
 *      This namespace contains module functions for CustomerTicketMessage.
 */
Core.Customer.TicketMessage = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Customer.TicketMessage
     * @function
     * @description
     *      This function initializes module functionality.
     */
    TargetNS.Init = function(){

        var Index,
            $Form,
            FieldID,
            TypeFieldUpdate,
            DestFieldUpdate,
            ServiceFieldUpdate,
            SLAFieldUpdate,
            PriorityFieldUpdate,
            DynamicFieldNames = Core.Config.Get('DynamicFieldNames');

        // bind event to Type field
        $('#TypeID').on('change', function () {
            TypeFieldUpdate = ['Dest', 'PriorityID', 'ServiceID', 'SLAID'];
            for (Index in DynamicFieldNames) {
                TypeFieldUpdate.push(DynamicFieldNames[Index]);
            }
            Core.AJAX.FormUpdate($('#NewCustomerTicket'), 'AJAXUpdate', 'TypeID', TypeFieldUpdate);
        });

        // bind event to Dest field (Queue)
        $('#Dest').on('change', function () {
            DestFieldUpdate = ['TypeID', 'PriorityID', 'ServiceID', 'SLAID'];
            for (Index in DynamicFieldNames) {
                DestFieldUpdate.push(DynamicFieldNames[Index]);
            }
            Core.AJAX.FormUpdate($('#NewCustomerTicket'), 'AJAXUpdate', 'Dest', DestFieldUpdate);
        });

        // bind event to Service field
        $('#ServiceID').on('change', function () {
            ServiceFieldUpdate = ['TypeID', 'Dest', 'PriorityID', 'SLAID'];
            for (Index in DynamicFieldNames) {
                ServiceFieldUpdate.push(DynamicFieldNames[Index]);
            }
            Core.AJAX.FormUpdate($('#NewCustomerTicket'), 'AJAXUpdate', 'ServiceID', ServiceFieldUpdate);
        });

        // bind event to SLA field
        $('#SLAID').on('change', function () {
            SLAFieldUpdate = ['TypeID', 'Dest', 'ServiceID', 'PriorityID', 'SignKeyID', 'CryptKeyID'];
            for (Index in DynamicFieldNames) {
                SLAFieldUpdate.push(DynamicFieldNames[Index]);
            }
            Core.AJAX.FormUpdate($('#NewCustomerTicket'), 'AJAXUpdate', 'SLAID', SLAFieldUpdate);
        });

        // bind event to Priority field
        $('#PriorityID').on('change', function () {
            PriorityFieldUpdate = ['TypeID', 'Dest', 'ServiceID', 'SLAID'];
            for (Index in DynamicFieldNames) {
                PriorityFieldUpdate.push(DynamicFieldNames[Index]);
            }
            Core.AJAX.FormUpdate($('#NewCustomerTicket'), 'AJAXUpdate', 'PriorityID', PriorityFieldUpdate);
        });

        // choose attachment
        $('#Attachment').on('change', function () {
            $Form = $('#Attachment').closest('form');
            Core.Form.Validate.DisableValidation($Form);
            $Form.find('#AttachmentUpload').val('1').end().submit();
        });

        // delete attachment
        $('button[id*=AttachmentDeleteButton]').on('click', function () {
            $Form = $(this).closest('form');
            FieldID = $(this).attr('id').split('AttachmentDeleteButton')[1];
            $('#AttachmentDelete' + FieldID).val(1);
            Core.Form.Validate.DisableValidation($Form);
            $Form.trigger('submit');
        });

    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Customer.TicketMessage || {}));
