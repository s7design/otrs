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
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get test user ID
        my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # get time object
        my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

        # get current system time
        my ( $Sec, $Min, $Hour, $Day, $Month, $Year, $WeekDay ) = $TimeObject->SystemTime2Date(
            SystemTime => $TimeObject->SystemTime(),
        );

        # create OutOfOffice params
        my @OutOfOfficeTime = (
            {
                Key   => 'OutOfOffice',
                Value => 1,
            },
            {
                Key   => 'OutOfOfficeStartYear',
                Value => $Year - 1,
            },
            {
                Key   => 'OutOfOfficeEndYear',
                Value => $Year + 1,
            },
            {
                Key   => 'OutOfOfficeStartMonth',
                Value => $Month,
            },
            {
                Key   => 'OutOfOfficeEndMonth',
                Value => $Month,
            },
            {
                Key   => 'OutOfOfficeStartDay',
                Value => $Day,
            },
            {
                Key   => 'OutOfOfficeEndDay',
                Value => $Day,
            },
        );

        # set OutOfOffice preference
        for my $OutOfOfficePreference (@OutOfOfficeTime) {
            $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
                UserID => $TestUserID,
                Key    => $OutOfOfficePreference->{Key},
                Value  => $OutOfOfficePreference->{Value},
            );
        }

        # clean up dashboard cache and refresh screen
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'Dashboard' );
        $Selenium->refresh();

        # test OutOfOffice plugin
        my $ExpectedResult = "$TestUserLogin until $Month/$Day/" . ( $Year + 1 );
        $Self->True(
            index( $Selenium->get_page_source(), $ExpectedResult ) > -1,
            "OutOfOffice message - found on screen"
        );
    }
);

1;
