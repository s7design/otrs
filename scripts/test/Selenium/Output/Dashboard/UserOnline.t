# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
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

        # get helper object
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::UnitTest::Helper' => {
                RestoreSystemConfiguration => 1,
            },
        );
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # set UserOnline sysconfig
        my %UserOnlineParam = (
            Block         => 'ContentSmall',
            CacheTTLLocal => 5,
            Default       => 1,
            Description   => '',
            Filter        => 'Agent',
            Group         => '',
            IdleMinutes   => 60,
            Limit         => 10,
            Module        => 'Kernel::Output::HTML::Dashboard::UserOnline',
            ShowEmail     => 0,
            SortBy        => 'UserFullname',
            Title         => 'Online'
        );
        $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => 'DashboardBackend###0400-UserOnline',
            Value => \%UserOnlineParam,
        );

        # create and login test customer
        my $TestCustomerUserLogin = $Helper->TestCustomerUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";
        $Selenium->Login(
            Type     => 'Customer',
            User     => $TestCustomerUserLogin,
            Password => $TestCustomerUserLogin,
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

        # clean up dashboard cache and refresh screen
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'Dashboard' );
        $Selenium->refresh();

        # test UserOnline plugin for agent
        my $ExpectedAgent = "$TestUserLogin $TestUserLogin";
        $Self->True(
            index( $Selenium->get_page_source(), $ExpectedAgent ) > -1,
            "$TestUserLogin - found on UserOnline plugin"
        );

        # switch to online customers and test UserOnline plugin for customers
        $Selenium->find_element("//a[contains(\@id, \'Customer' )]")->click();
        sleep 20;
        my $ExpectedCustomer = "$TestCustomerUserLogin $TestCustomerUserLogin";
        $Self->True(
            index( $Selenium->get_page_source(), $ExpectedCustomer ) > -1,
            "$TestCustomerUserLogin - found on UserOnline plugin"
        );
    }
);

1;
