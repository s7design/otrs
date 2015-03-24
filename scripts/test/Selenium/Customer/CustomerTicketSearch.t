# --
# CustomerTiketSearch.t - frontend tests for CustomerTiketSearch
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use Data::Dumper;

use vars (qw($Self));

use Kernel::System::UnitTest::Helper;
use Kernel::System::UnitTest::Selenium;

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

my $Selenium = Kernel::System::UnitTest::Selenium->new(
    Verbose => 1,
);

$Selenium->RunTest(
    sub {

        my $Helper = Kernel::System::UnitTest::Helper->new(
            RestoreSystemConfiguration => 0,
        );

        # create and login test customer
        my $TestCustomerUserLogin = $Helper->TestCustomerUserCreate(
        Groups => ['admin'],
             ) || die "Did not get test user";

        $Selenium->Login(
            Type => 'Customer',
            User => $TestCustomerUserLogin,
            Password => $TestCustomerUserLogin,
        );

        # click on 'Create your first ticket'
        $Selenium->find_element( ".Button", 'css' )->click();

        # navigate to customer ticket search
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');
        $Selenium->get("${ScriptAlias}customer.pl?Action=CustomerTicketSearch");

        # check overview screen
        for my $ID (
            qw(Profile TicketNumber CustomerID From To Cc Subject Body ServiceIDs TypeIDs PriorityIDs StateIDs
                NoTimeSet Date DateRange TicketCreateTimePointStart TicketCreateTimePoint TicketCreateTimePointFormat
                TicketCreateTimeStartMonth TicketCreateTimeStartDay TicketCreateTimeStartYear TicketCreateTimeStartDayDatepickerIcon
                TicketCreateTimeStopMonth TicketCreateTimeStopDay TicketCreateTimeStopYear TicketCreateTimeStopDayDatepickerIcon
                SaveProfile Submit ResultForm)
            )
        {
            my $Element = $Selenium->find_element( "#$ID", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();
        }

        # create ticket for test scenario
        my $TitleRandom = 'Title' . $Helper->GetRandomID();
        my $TicketID = $TicketObject->TicketCreate(
            Title        => $TitleRandom,
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'open',
            CustomerUser => $TestCustomerUserLogin,
            OwnerID      => 1,
            UserID       => 1,
        );
        $Self->True(
            $TicketID,
            "Created $TitleRandom ticket",
        );

        # get test ticket number
        my %Ticket = $TicketObject->TicketGet(
            TicketID => $TicketID,
        );

        # input ticket number as search parametar
        $Selenium->find_element( "#TicketNumber", 'css' )->send_keys( $Ticket{TicketNumber} );
        $Selenium->find_element( "#TicketNumber", 'css' )->submit();

        # check for expected result
        $Self->True(
            index( $Selenium->get_page_source(), $TitleRandom ) > -1,
            "Ticket $TitleRandom found on page",
        );

    }
);

1;