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

        # get time object
        my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

        # set fixed time for test purposes
        $Helper->FixedTimeSet(
            $TimeObject->TimeStamp2SystemTime( String => '2014-12-12 00:00:00' ),
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

        # get user object
        my $UserObject = $Kernel::OM->Get('Kernel::System::User');

        # get test user ID
        my $TestUserID = $UserObject->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # create test queue
        my $QueueName = "Queue" . $Helper->GetRandomID();
        my $QueueID   = $Kernel::OM->Get('Kernel::System::Queue')->QueueAdd(
            Name            => $QueueName,
            ValidID         => 1,
            GroupID         => 1,
            SolutionTime    => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            Comment         => 'Selenium Queue',
            UserID          => 1,
        );
        $Self->True(
            $QueueID,
            "Queue add $QueueName - ID $QueueID",
        );

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # create test ticket
        my $TicketID = $TicketObject->TicketCreate(
            Title        => 'Selenium Test Ticket',
            QueueID      => $QueueID,
            Lock         => 'lock',
            Priority     => '3 normal',
            State        => 'pending reminder',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        );
        $Self->True(
            $TicketID,
            "Ticket is created - ID $TicketID",
        );

        # wait 5 minutes to have escalation trigger
        $Helper->FixedTimeAddSeconds(300);

        # create test params
        my @Test = (
            {
                DashboardName => 'TicketPendingReminder',
                SysConfigName => 'DashboardBackend###0100-TicketPendingReminder',
            },
            {
                DashboardName => 'TicketEscalation',
                SysConfigName => 'DashboardBackend###0110-TicketEscalation',
            },
            {
                DashboardName => 'TicketNew',
                SysConfigName => 'DashboardBackend###0120-TicketNew',
            },
            {
                DashboardName => 'TicketOpen',
                SysConfigName => 'DashboardBackend###0130-TicketOpen',
            },
        );

        # test if ticket is shown in each dashboard ticket generic plugin
        for my $DashboardTest (@Test) {

            # set ticket state depending on the stage in test
            if ( $DashboardTest->{DashboardName} eq 'TicketNew' ) {
                my $Success = $TicketObject->TicketStateSet(
                    State    => 'new',
                    TicketID => $TicketID,
                    UserID   => 1,
                );
                $Self->True(
                    $Success,
                    "Changed ticket state to - New"
                );
            }
            if ( $DashboardTest->{DashboardName} eq 'TicketOpen' ) {
                my $Success = $TicketObject->TicketStateSet(
                    State    => 'open',
                    TicketID => $TicketID,
                    UserID   => 1,
                );
                $Self->True(
                    $Success,
                    "Changed ticket state to - Open"
                );
            }

            # get sysconfig object
            my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

            # disable all dashboard plugins
            my $Config = $Kernel::OM->Get('Kernel::Config')->Get('DashboardBackend');
            $SysConfigObject->ConfigItemUpdate(
                Valid => 0,
                Key   => 'DashboardBackend',
                Value => \%$Config,
            );

            # enable current needed dashboard plugin sysconfig
            $SysConfigObject->ConfigItemReset(
                Name => $DashboardTest->{SysConfigName},
            );

            # refresh dashboard screen and clean it's cache
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => 'Dashboard',
            );
            $Selenium->refresh();

            # switch view to all tickets on TicketPendingReminder plugin
            if ( $DashboardTest->{DashboardName} eq 'TicketPendingReminder' ) {
                $Selenium->find_element( "#Dashboard0100-TicketPendingReminderAll", 'css' )->click();
                $Selenium->WaitFor( JavaScript => 'return $(".MasterAction").length' );
            }

            # check for test ticket on current dashboard plugin
            $Self->True(
                index( $Selenium->get_page_source(), "Action=AgentTicketZoom;TicketID=$TicketID" ) > -1,
                "$DashboardTest->{DashboardName} dashboard plugin test ticket link - found",
            );

        }

        # delete test tickets
        my $Success = $TicketObject->TicketDelete(
            TicketID => $TicketID,
            UserID   => 1,
        );
        $Self->True(
            $Success,
            "Delete ticket - ID $TicketID"
        );

        # delete test queue
        $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL => "DELETE FROM queue WHERE id = $QueueID",
        );
        $Self->True(
            $Success,
            "Delete queue - ID $QueueID",
        );

        # make sure cache is correct
        for my $Cache (qw(Ticket Queue)) {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $Cache,
            );
        }
    }
);

1;
