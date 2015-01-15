# --
# AdminGenericAgent.t - frontend tests for AdminGenericAgent.t
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

        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # Create Ticket to test AdminGenericAgent frontend
        my $TicketID = $TicketObject->TicketCreate(
            Title        => 'Testticket for Untittest of the Generic Agent',
            Queue        => 'Raw',
            Lock         => 'unlock',
            PriorityID   => 1,
            StateID      => 1,
            CustomerNo   => '123465',
            CustomerUser => 'customerUnitTest@example.com',
            OwnerID      => 1,
            UserID       => 1,
        );

        my $ArticleID = $TicketObject->ArticleCreate(
            TicketID       => $TicketID,
            ArticleType    => 'note-internal',
            SenderType     => 'agent',
            From           => 'Some Agent <email@example.com>',
            To             => 'Customer A <customer-a@example.com>',
            Cc             => 'Customer B <customer-b@example.com>',
            ReplyTo        => 'Customer B <customer-b@example.com>',
            Subject        => 'some short description',
            Body           => 'the message text Perl modules provide a range of',
            ContentType    => 'text/plain; charset=ISO-8859-15',
            HistoryType    => 'OwnerUpdate',
            HistoryComment => 'Some free text!',
            UserID         => 1,
            NoAgentNotify  => 1,
        );

        my $TicketNumber = $TicketObject->TicketNumberLookup(
            TicketID => $TicketID,
            UserID   => 1,
        );

        $Selenium->get("${ScriptAlias}index.pl?Action=AdminGenericAgent");

        my $RandomID = $Helper->GetRandomID();

        # check overview AdminGenericAgent
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );

        # check add job page
        $Selenium->find_element( "a.Create", 'css' )->click();

        my $Element = $Selenium->find_element( "#Profile", 'css' );
        $Element->is_displayed();
        $Element->is_enabled();

        # check Automatic execution (multiple tickets) widget
        $Selenium->find_element("html/body/div[6]/div[2]/form/div[2]/div[1]/div/a")->click();

        # check Even based execution widget
        $Selenium->find_element("html/body/div[6]/div[2]/form/div[3]/div[1]/div/a")->click();

        # check Select Tickets widget
        $Selenium->find_element("html/body/div[6]/div[2]/form/div[4]/div[1]/div/a")->click();

        # check Update/Add Ticket Attribued widget
        $Selenium->find_element("html/body/div[6]/div[2]/form/div[5]/div[1]/div/a")->click();

        # check Add Note widget
        $Selenium->find_element("html/body/div[6]/div[2]/form/div[6]/div[1]/div/a")->click();

        # check Execute Ticket Commands widget
        $Selenium->find_element("html/body/div[6]/div[2]/form/div[7]/div[1]/div/a")->click();

        # check Execude Custome Module widget
        $Selenium->find_element("html/body/div[6]/div[2]/form/div[8]/div[1]/div/a")->click();

        # create test job
        $Selenium->find_element( "#Profile",      'css' )->send_keys($RandomID);
        $Selenium->find_element( "#TicketNumber", 'css' )->send_keys($TicketNumber);
        $Selenium->find_element( "#Profile",      'css' )->submit();

        # check if test job show on AdminGenericAgent
        $Self->True(
            index( $Selenium->get_page_source(), $RandomID ) > -1,
            "$RandomID job found on page",
        );

        # edit test job
        $Selenium->find_element( $RandomID, 'link_text' )->click();

        # edit test job to delete test ticket
        $Selenium->find_element("html/body/div[6]/div[2]/form/div[7]/div[1]/div/a")->click();
        $Selenium->find_element( "#NewDelete option[value='1']", 'css' )->click();
        $Selenium->find_element( "#Profile",                     'css' )->submit();

        # run test job
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Run;Profile=$RandomID\' )]")->click();

        # check if test job show expected result
        $Self->True(
            index( $Selenium->get_page_source(), $TicketNumber ) > -1,
            "$TicketNumber found on page",
        );

        # execute test job
        $Selenium->find_element("//a[contains(\@href, \'Subaction=RunNow' )]")->click();

        # delete test job
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Delete;Profile=$RandomID\' )]")->click();

        }

);

1;
