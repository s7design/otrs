# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get needed objects
        my $Helper       = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

        # check if cloud services are disabled
        my $CloudServicesDisabled = $ConfigObject->Get('CloudServices::Disabled');

        if ($CloudServicesDisabled) {
            $Self->True(
                1,
                "Cloud services are disabled - there are no news and test is finished",
            );
            return 1;
        }

        # disable all dashboard plugins
        my $Config = $ConfigObject->Get('DashboardBackend');
        $Helper->ConfigSettingChange(
            Valid => 0,
            Key   => 'DashboardBackend',
            Value => $Config,
        );

        # get dashboard News plugin default sysconfig
        my %NewsConfig = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemGet(
            Name    => 'DashboardBackend###0405-News',
            Default => 1,
        );

        # set dashboard News plugin to valid
        %NewsConfig = map { $_->{Key} => $_->{Content} }
            grep { defined $_->{Key} } @{ $NewsConfig{Setting}->[1]->{Hash}->[1]->{Item} };

        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'DashboardBackend###0405-News',
            Value => \%NewsConfig,
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # navigate dashboard screen and wait until page has loaded
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentDashboard");

        # check if News plugin has correct title
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#Dashboard0405-News-box .Header h2:contains(\"OTRS News\")').length;"
            ),
            1,
            "News dashboard plugin title 'OTRS News' is found",
        );

        # check if News plugin has correct table
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#Dashboard0405-News table.DataTable').length;"
            ),
            1,
            "News dashboard plugin table is found",
        );
    }
);

1;
