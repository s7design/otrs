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

        # get helper object
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::UnitTest::Helper' => {
                RestoreSystemConfiguration => 1,
            },
        );
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # reset 'DashboardBackend###0120-TicketNew' sysconfig
        $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemReset(
            Name => 'DashboardBackend###0120-TicketNew',
        );

        # set 'DashboardBackend###0120-TicketNew' sysconfig
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => "DashboardBackend###0120-TicketNew",
            Value => {
                'Attributes'     => 'StateType=new;SortBy=Priority;OrderBy=Down;',
                'Block'          => 'ContentLarge',
                'CacheTTLLocal'  => '0.001',
                'Default'        => '1',
                'DefaultColumns' => {
                    'Age'                    => '2',
                    'Changed'                => '1',
                    'Created'                => '1',
                    'CustomerCompanyName'    => '1',
                    'CustomerID'             => '1',
                    'CustomerName'           => '1',
                    'CustomerUserID'         => '1',
                    'EscalationResponseTime' => '1',
                    'EscalationSolutionTime' => '1',
                    'EscalationTime'         => '1',
                    'EscalationUpdateTime'   => '1',
                    'Lock'                   => '1',
                    'Owner'                  => '1',
                    'PendingTime'            => '1',
                    'Priority'               => '2',
                    'Queue'                  => '2',
                    'Responsible'            => '1',
                    'SLA'                    => '1',
                    'Service'                => '1',
                    'State'                  => '1',
                    'TicketNumber'           => '2',
                    'Title'                  => '2',
                    'Type'                   => '1'
                },
                'Description' => 'All new tickets, these tickets have not been worked on yet',
                'Filter'      => 'All',
                'Group'       => '',
                'Limit'       => '10',
                'Module'      => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
                'Permission'  => 'rw',
                'Time'        => 'Age',
                'Title'       => 'New Tickets'
            },
        );

        # create test user
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        # get test user ID
        my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # create test queue
        my $QueueName = "Queue" . $Helper->GetRandomID();
        my $QueueID   = $Kernel::OM->Get('Kernel::System::Queue')->QueueAdd(
            Name            => $QueueName,
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            Comment         => 'Selenium Queue',
            UserID          => $TestUserID,
        );
        $Self->True(
            $QueueID,
            "Queue ID $QueueID is created",
        );

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # create 11 test tickets
        my @TicketIDs;
        my @TicketNumbers;
        for my $TicketCreate ( 1 .. 11 ) {
            my $TicketNumber = $TicketObject->TicketCreateNumber();
            my $TicketID     = $TicketObject->TicketCreate(
                TN           => $TicketNumber,
                Title        => 'Selenium Test Ticket',
                QueueID      => $QueueID,
                Lock         => 'lock',
                Priority     => '3 normal',
                State        => 'new',
                CustomerID   => '123465',
                CustomerUser => 'customer@example.com',
                OwnerID      => $TestUserID,
                UserID       => $TestUserID,
            );
            $Self->True(
                $TicketID,
                "Ticket is created - ID $TicketID",
            );
            push @TicketNumbers, $TicketNumber;
            push @TicketIDs,     $TicketID;
        }

        # update last ticket to priority '1 very low' for test purpose
        my $Success = $TicketObject->TicketPrioritySet(
            TicketID => $TicketIDs[10],
            Priority => '1 very low',
            UserID   => $TestUserID,
        );
        $Self->True(
            $Success,
            "Ticket ID $TicketIDs[10] updated priority to '1 very low'"
        );

        # login
        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # navigate to AgentPreferences screen
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentPreferences");

        # set MyQueue preferences
        $Selenium->execute_script("\$('#QueueID').val('$QueueID').trigger('redraw.InputField').trigger('change');");
        $Selenium->find_element( "#QueueIDUpdate", 'css' )->VerifiedClick();

        # login test user again
        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # click on 'Tickets in My Queues'
        $Selenium->find_element( "#Dashboard0120-TicketNewMyQueues", 'css' )->click();

        # wait for AJAX to load
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Loading").length' );

        # verify sorting by priority as initial sort on loading page
        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Priority, sorted descending' )]"),
            "Sorting by priority on loading page",
        );

        # verify ticket with different priority is not present without filter, it's on second page
        $Self->True(
            index( $Selenium->get_page_source(), 'Queue, filter not active' ) > -1,
            "There is no filter for 'New Tickets' widget",
        );
        $Self->True(
            index( $Selenium->get_page_source(), $TicketNumbers[10] ) == -1,
            "Ticket with priority '1 very low' is not found on screen without filter",
        );

        # click to set filter for queue column
        $Selenium->find_element("//a[contains(\@title, \'Queue, filter not active' )]")->click();

        # wait for filter options to load
        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $("#ColumnFilterQueue0120-TicketNew:visible").length'
        );

        # set test queue as filter
        $Selenium->find_element( "#ColumnFilterQueue0120-TicketNew", 'css' )->click();
        $Selenium->execute_script(
            "\$('#ColumnFilterQueue0120-TicketNew').val('$QueueID').trigger('redraw.ColumnFilter').trigger('change');"
        );

        # wait for AJAX to load
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Loading").length' );

     # verify ticket with different priority is not present on screen with filter, it's still on second page
     # see bug #11422 ( http://bugs.otrs.org/show_bug.cgi?id=11422 ), there is no change in order when activating filter
        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Queue, filter active' )]"),
            "There is filter for queue column in 'New Tickets' widget",
        );
        $Self->True(
            index( $Selenium->get_page_source(), $TicketNumbers[10] ) == -1,
            "Ticket with priority '1 very low' is not found on screen with filter active",
        );

        # verify priority order by is not changed
        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Priority, sorted descending' )]"),
            "Priority column order by is not changed",
        );

        # click on priority column - order by is 'Up'
        $Selenium->find_element( "#PriorityOverviewControl0120-TicketNew", 'css' )->click();

        # wait for AJAX to load
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Loading").length' );

        # verify priority order by is changed to 'Up'
        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Priority, sorted ascending' )]"),
            "Priority column order by is changed",
        );

        # verify ticket with priority '1 very low' is now on screen
        $Self->True(
            index( $Selenium->get_page_source(), $TicketNumbers[10] ) > -1,
            "Ticket with priority '1 very low' is found on screen with filter active and changed priority column order by",
        );

        # remove queue filter to test that priority order by column will remain same
        # click to set filter for queue column
        $Selenium->find_element("//a[contains(\@title, \'Queue, filter active' )]")->click();

        # wait for filter options to load
        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $("#ColumnFilterQueue0120-TicketNew:visible").length'
        );

        # remove queue filter
        $Selenium->find_element( "#ColumnFilterQueue0120-TicketNew", 'css' )->click();
        $Selenium->execute_script(
            "\$('#ColumnFilterQueue0120-TicketNew').val('DeleteFilter').trigger('redraw.ColumnFilter').trigger('change');"
        );

        # wait for AJAX to load
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Loading").length' );

        # verify filter is removed
        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Queue, filter not active' )]"),
            "There is filter for queue column in 'New Tickets' widget",
        );

        # verify priority order remained same after removing filter
        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Priority, sorted ascending' )]"),
            "Priority column order by remained same after removing filter",
        );

        # verify ticket with priority '1 very low' is still on screen
        $Self->True(
            index( $Selenium->get_page_source(), $TicketNumbers[10] ) > -1,
            "Ticket with priority '1 very low' is found on screen without filter",
        );

        # verify change of order by in priority column on click
        $Selenium->find_element( "#PriorityOverviewControl0120-TicketNew", 'css' )->click();

        # wait for AJAX to load
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && !$(".Loading").length' );

        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Priority, sorted descending' )]"),
            "Priority column order by changed",
        );

        # delete test tickets
        for my $Ticket (@TicketIDs) {
            my $Success = $TicketObject->TicketDelete(
                TicketID => $Ticket,
                UserID   => 1,
            );
            $Self->True(
                $Success,
                "Ticket ID $Ticket is deleted"
            );
        }

        # get DB object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # delete personal queue for test agent
        $Success = $DBObject->Do(
            SQL => "DELETE FROM personal_queues WHERE queue_id = $QueueID",
        );
        $Self->True(
            $Success,
            "Personal queue is deleted",
        );

        # delete test queue
        $Success = $DBObject->Do(
            SQL => "DELETE FROM queue WHERE id = $QueueID",
        );
        $Self->True(
            $Success,
            "Queue ID $QueueID is deleted",
        );
    }

);

1;
