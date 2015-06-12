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
                }
        );
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get sysconfig object
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        # enable PDF output
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'PDF',
            Value => 1
        );

        # create test customer user and login
        my $TestCustomerUserLogin = $Helper->TestCustomerUserCreate(
            Groups => ['users'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Customer',
            User     => $TestCustomerUserLogin,
            Password => $TestCustomerUserLogin,
        );

        # get needed data
        my @User = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerIDs(
            User => $TestCustomerUserLogin,
        );
        my $TestCustomerID = $User[0];

        # get Ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # create test customer
        my $TicketNumber = $TicketObject->TicketCreateNumber();
        my $TicketID     = $TicketObject->TicketCreate(
            TN           => $TicketNumber,
            Title        => 'Selenium Test Ticket',
            Queue        => 'Raw',
            Priority     => '3 normal',
            Lock         => 'unlock',
            State        => 'open',
            CustomerID   => $TestCustomerID,
            CustomerUser => "$TestCustomerUserLogin\@localhost.com",
            OwnerID      => 1,
            UserID       => 1,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # navigate to CustomerTicketZoom screen
        $Selenium->get("${ScriptAlias}customer.pl?Action=CustomerTicketZoom;TicketNumber=$TicketNumber");

        # click on print menu item
        $Selenium->find_element("//a[contains(\@href, \'Action=CustomerTicketPrint;TicketID=$TicketID\' )]")->click();

        # switch to another window
        my $Handles = $Selenium->get_window_handles();
        $Selenium->switch_to_window( $Handles->[1] );

        # wait until print screen is loaded
        # ACTIVESLEEP:
        # for my $Second ( 1 .. 20 ) {
        #     if ( index( $Selenium->get_page_source(), "$TitleRandom" ) > -1, )  {
        #         last ACTIVESLEEP;
        #     }
        #     sleep 1;
        # }
        sleep 3;

        # check for printed values of test ticket
        $Self->True(
            index( $Selenium->get_page_source(), "printed by $TestCustomerUserLogin" ) > -1,
            "Header data is found on print screen - printed by $TestCustomerUserLogin",
        );

        $Self->True(
            index( $Selenium->get_page_source(), "State:" ) > -1
                && index( $Selenium->get_page_source(), "open" ) > -1,
            "State: open - found on print screen",
        );

        $Self->True(
            index( $Selenium->get_page_source(), "Queue:" ) > -1
                && index( $Selenium->get_page_source(), "3 normal" ) > -1,
            "Queue: Raw - found on print screen",
        );

        $Self->True(
            index( $Selenium->get_page_source(), "CustomerID:" ) > -1
                && index( $Selenium->get_page_source(), "$TestCustomerUserLogin" ) > -1,
            "CustomerID: $TestCustomerUserLogin - found on print screen",
        );

        $Self->True(
            index( $Selenium->get_page_source(), "Priority:" ) > -1
                && index( $Selenium->get_page_source(), "3 normal" ) > -1,
            "Priority: 3 normal - found on print screen",
        );

        # delete test ticket
        my $Success = $TicketObject->TicketDelete(
            TicketID => $TicketID,
            UserID   => 1,
        );
        $Self->True(
            $Success,
            "Ticket is deleted - $TicketID"
        );

        # make sure the cache is correct
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
            Type => 'Ticket',
        );

    }
);

1;
