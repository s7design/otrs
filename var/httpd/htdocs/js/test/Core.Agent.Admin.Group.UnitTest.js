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
Core.Agent.Admin = Core.Agent.Admin || {};

Core.Agent.Admin.Group = (function (Namespace) {
    Namespace.RunUnitTests = function(){

        var CheckConfirmJS = function (value) {
                var lastConfirm = undefined;
                window.confirm = function (message) {
                    lastConfirm = message;
                    return value;     // set confirm to true or false
                };
                window.getLastConfirm = function () {
                    var result = lastConfirm;
                    lastConfirm = undefined;
                    return result;
                };
            };

        module('Core.Agent.Admin.Group');

        test('Core.Agent.Admin.Group.AdminGroupCheck()', function(){
            var $TestForm = $('<form id="TestForm"></form>');

            expect(4);

            $TestForm.append('<input name="Name" id="GroupName" type="text">');
            $TestForm.append('<input name="Name" id="GroupOldName" type="text">');
            $('body').append($TestForm);

            $('#GroupName').val('admin test');
            ok(Core.Agent.Admin.Group.AdminGroupCheck(), 'AdminGroupCheck return 1 - GroupOldName is empty');

            $('#GroupOldName').val('admin');
            CheckConfirmJS(true);
            ok(Core.Agent.Admin.Group.AdminGroupCheck(), 'AdminGroupCheck return 1 - confirm is accepted');
            equal(window.getLastConfirm(), Core.Language.Translate("WARNING: When you change the name of the group 'admin', before making the appropriate changes in the SysConfig, you will be locked out of the administrations panel! If this happens, please rename the group back to admin per SQL statement."), 'Check confirm message');

            CheckConfirmJS(false);
            equal(Core.Agent.Admin.Group.AdminGroupCheck(), false,'AdminGroupCheck return 0 - confirm is canceled');

            $('#TestForm').remove();

        });
    };

    return Namespace;
}(Core.Agent.Admin.Group || {}));
