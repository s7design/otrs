# --
# AgentStatsOverview.t - frontend tests for AgentStatsOverview
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
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Selenium' => {
        Verbose => 1,
        }
);
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::UnitTest::Helper' => {
                RestoreSystemConfiguration => 0,
                }
        );
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users', 'stats' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');
        $Selenium->get("${ScriptAlias}index.pl?Action=AgentStats;Subaction=Overview");

        # check layout screen
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );

        # create params for test stats overview
        my @Tests = (
            {
                Title       => 'Changes of status in a monthly overview',
                Object      => 'StateAction',
                Description => 'Monthly overview, which reports status changes per day of a selected',
                Format      => 'Print',
                StatID      => '1',
            },
            {
                Title       => 'List of tickets created last month',
                Object      => 'Ticketlist',
                Description => 'List of all tickets created last month. Order by age.',
                Format      => 'CSV',
                StatID      => '2',
            },
            {
                Title       => 'New Tickets',
                Object      => 'TicketAccumulation',
                Description => 'Total number of new tickets per day and queue which have been created',
                Format      => 'Print',
                StatID      => '3',
            },
            {
                Title       => 'List of the most time-consuming tickets',
                Object      => 'Ticketlist',
                Description => 'List of tickets closed last month which required the most time to',
                Format      => 'CSV',
                StatID      => '4',
            },
            {
                Title       => 'List of tickets closed, sorted by solution time',
                Object      => 'Ticketlist',
                Description => 'List of tickets closed last month, sorted by solution time.',
                Format      => 'CSV',
                StatID      => '5',
            },
            {
                Title       => 'List of open tickets, sorted by time left until response deadline expires',
                Object      => 'Ticketlist',
                Description => 'List of open tickets, sorted by time left until response deadline',
                Format      => 'CSV',
                StatID      => '6',
            },
            {
                Title       => 'Overview about all tickets in the system',
                Object      => 'TicketAccumulation',
                Description => 'Current state of all tickets in the system without time restrictions.',
                Format      => 'CSV',
                StatID      => '7',
            },
            {
                Title       => 'List of open tickets, sorted by time left until escalation deadline expires',
                Object      => 'Ticketlist',
                Description => 'List of open tickets, sorted by time left until escalation deadline',
                Format      => 'CSV',
                StatID      => '8',
            },
            {
                Title       => 'List of tickets closed, sorted by response time.',
                Object      => 'Ticketlist',
                Description => 'List of tickets closed last month, sorted by response time.',
                Format      => 'CSV',
                StatID      => '9',
            },
            {
                Title       => 'List of open tickets, sorted by time left until solution deadline expires',
                Object      => 'Ticketlist',
                Description => 'List of open tickets, sorted by time left until solution deadline',
                Format      => 'CSV',
                StatID      => '10',
            },
            {
                Title       => 'List of tickets closed last month',
                Object      => 'Ticketlist',
                Description => 'List of all tickets closed last month. Order by age.',
                Format      => 'CSV',
                StatID      => '11',
            },
        );

        # test AgentStats overview for default statistics
        for my $AgentStatsOverview (@Tests) {

            # click on default statistic
            $Selenium->find_element(
                "//a[contains(\@href, \'Action=AgentStats;Subaction=View;StatID=$AgentStatsOverview->{StatID}\' )]")
                ->click();

            for my $StatsParam (qw( Title Object Description Format)) {

                # check for stats param on screen
                $Self->True(
                    index( $Selenium->get_page_source(), $AgentStatsOverview->{$StatsParam} ) > -1,
                    "StatID=$AgentStatsOverview->{StatID} - $StatsParam = '$AgentStatsOverview->{$StatsParam}' - found on screen"
                );
            }

            $Selenium->go_back();

        }

        }
);

1;
