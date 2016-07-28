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
 * @namespace Core.Pagination
 * @memberof Core
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for pagination.
 */
Core.Pagination = (function (TargetNS) {

    /**
     * @private
     * @name PageNumberEvents
     * @memberof Core.Pagination
     * @function
     * @param {Object} Data - The data for creating events for html element.
     * @description
     *      Creates events for page number buttons.
     */
    function PageNumberEvents(Data) {
        var $Container;

        $('#' + Data.IDPrefix + 'Page' + Data.PageNumber).off('click').on('click', function(){
            $Container = $(this).parents('.WidgetSimple');
            $Container.addClass('Loading');
            Core.AJAX.ContentUpdate($('#' + Data.AjaxReplace), Data.BaselinkAll, function () {
                $Container.removeClass('Loading');
                if (typeof Core.Config.Get('PaginationData') !== 'undefined') {
                    TargetNS.Init();
                }
            });
            return false;
        });
    }

    /**
     * @private
     * @name PageBackEvents
     * @memberof Core.Pagination
     * @function
     * @param {Object} Data - The data for creating events for html element.
     * @description
     *      Creates events for back buttons.
     */
    function PageBackEvents(Data) {
        var $Container;

        $('#' + Data.IDPrefix + 'PageAllBack').off('click').on('click', function(){
            $Container = $(this).parents('.WidgetSimple');
            $Container.addClass('Loading');
            Core.AJAX.ContentUpdate($('#' + Data.AjaxReplace), Data.BaselinkAllBack, function () {
                $Container.removeClass('Loading');
                if (typeof Core.Config.Get('PaginationData') !== 'undefined') {
                    TargetNS.Init();
                }
            });
            return false;
        });
        $('#' + Data.IDPrefix + 'PageOneBack').off('click').on('click', function(){
            $Container = $(this).parents('.WidgetSimple');
            $Container.addClass('Loading');
            Core.AJAX.ContentUpdate($('#' + Data.AjaxReplace), Data.BaselinkOneBack, function () {
                $Container.removeClass('Loading');
                if (typeof Core.Config.Get('PaginationData') !== 'undefined') {
                    TargetNS.Init();
                }
            });
            return false;
        });
    }

    /**
     * @private
     * @name PageForwardEvents
     * @memberof Core.Pagination
     * @function
     * @param {Object} Data - The data for creating events for html element.
     * @description
     *      Creates events for forward buttons.
     */
    function PageForwardEvents(Data) {
        var $Container;

        $('#' + Data.IDPrefix + 'PageOneForward').off('click').on('click', function(){
            $Container = $(this).parents('.WidgetSimple');
            $Container.addClass('Loading');
            Core.AJAX.ContentUpdate($('#' + Data.AjaxReplace), Data.BaselinkOneForward, function () {
                $Container.removeClass('Loading');
                if (typeof Core.Config.Get('PaginationData') !== 'undefined') {
                    TargetNS.Init();
                }
            });
            return false;
        });
        $('#' + Data.IDPrefix + 'PageAllForward').off('click').on('click', function(){
            $Container = $(this).parents('.WidgetSimple');
            $Container.addClass('Loading');
            Core.AJAX.ContentUpdate($('#' + Data.AjaxReplace), Data.BaselinkAllForward, function () {
                $Container.removeClass('Loading');
                if (typeof Core.Config.Get('PaginationData') !== 'undefined') {
                    TargetNS.Init();
                }
            });
            return false;
        });
    }

    /**
     * @name Init
     * @memberof Core.Pagination
     * @function
     * @description
     *      This function initiates JS functionality.
     */
    TargetNS.Init = function () {
        var Index,
            PageIndex,
            PaginationData = Core.Config.Get('PaginationData') || [];

        for (Index in PaginationData) {
            if (typeof PaginationData[Index].Page === 'object' && PaginationData[Index].Page.length > 1) {
                for (PageIndex in PaginationData[Index].Page) {
                    PageNumberEvents(PaginationData[Index].Page[PageIndex]);
                }
            }

            if (typeof PaginationData[Index].PageBack !== 'undefined') {
                PageBackEvents(PaginationData[Index].PageBack);
            }

            if (typeof PaginationData[Index].PageForward !== 'undefined') {
                PageForwardEvents(PaginationData[Index].PageForward);
            }
        }
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Pagination || {}));
