# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
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

        # enable ticket responsible and watch feature
        for my $SysConfigResWatch (qw( Responsible Watcher )) {
            $SysConfigObject->ConfigItemUpdate(
                Valid => 1,
                Key   => "Ticket::$SysConfigResWatch",
                Value => 1
            );
        }

        # get menu config params
        my @TicketMenu = (
            {
                SysConfigItem => {
                    Active      => "AgentTicketMove",
                    Description => "Delete this ticket",
                    Link        => "Action=AgentTicketMove;TicketID=[% Data.TicketID %];DestQueue=Delete",
                    Module      => "Kernel::Output::HTML::TicketMenu::Generic",
                    Name        => "Delete",
                    PopupType   => "",
                    Target      => "",
                },
                Key => "Ticket::Frontend::MenuModule###460-Delete",
            },
            {
                SysConfigItem => {
                    Active      => "AgentTicketMove",
                    Description => "Mark this ticket as junk!",
                    Link        => "Action=AgentTicketMove;TicketID=[% Data.TicketID %];DestQueue=Junk",
                    Module      => "Kernel::Output::HTML::TicketMenu::Generic",
                    Name        => "Spam",
                    PopupType   => "",
                    Target      => "",
                },
                Key => "Ticket::Frontend::MenuModule###470-Junk",
            },
            {
                SysConfigItem => {
                    Active      => "AgentTicketMove",
                    Description => "Delete this ticket",
                    Link        => "Action=AgentTicketMove;TicketID=[% Data.TicketID %];DestQueue=Delete",
                    Module      => "Kernel::Output::HTML::TicketMenu::Generic",
                    Name        => "Delete",
                    PopupType   => "",
                    Target      => "",
                },
                Key => "Ticket::Frontend::PreMenuModule###450-Delete",
            },
            {
                SysConfigItem => {
                    Active      => "AgentTicketMove",
                    Description => "Mark as Spam!",
                    Link        => "Action=AgentTicketMove;TicketID=[% Data.TicketID %];DestQueue=Delete",
                    Module      => "Kernel::Output::HTML::TicketMenu::Generic",
                    Name        => "Spam",
                    PopupType   => "",
                    Target      => "",
                },
                Key => "Ticket::Frontend::PreMenuModule###460-Spam",
            },
        );

        # enable delete and spam menu in sysconfig
        for my $SysConfigItem (@TicketMenu) {
            $Kernel::OM->Get('Kernel::Config')->Set(
                Key   => $SysConfigItem->{Key},
                Value => $SysConfigItem->{SysConfigItem},
            );
            $SysConfigObject->ConfigItemUpdate(
                Valid => 1,
                Key   => $SysConfigItem->{Key},
                Value => $SysConfigItem->{SysConfigItem},
            );
        }

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

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # create test ticket
        my $TicketID = $TicketObject->TicketCreate(
            Title        => 'Some Ticket Title',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => 'TestCustomer',
            CustomerUser => 'customer@example.com',
            OwnerID      => $TestUserID,
            UserID       => $TestUserID,
        );

        $Self->True(
            $TicketID,
            "TicketID $TicketID - created"
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # go to raw queue view with focus on created test ticket
        $Selenium->VerifiedGet(
            "${ScriptAlias}index.pl?Action=AgentTicketQueue;Filter=Unlocked;OrderBy=Down;QueueID=2;SortBy=Age;View=Preview;"
        );

        # create pre menu module test params
        my @PreMenuModule = (
            {
                Name      => "Lock",
                NameForID => "Lock",
                Action    => "AgentTicket"
            },
            {
                Name      => "Zoom",
                NameForID => "Zoom",
                Action    => "AgentTicketZoom",
            },
            {
                Name      => "History",
                NameForID => "History",
                Action    => "AgentTicketHistory",
            },
            {
                Name      => "Priority",
                NameForID => "Priority",
                Action    => "AgentTicketPriority",
            },
            {
                Name      => "Note",
                NameForID => "Note",
                Action    => "AgentTicketNote",
            },
            {
                Name      => "Move",
                NameForID => "DestQueueID",
                Action    => "AgentTicketMove",
            },
            {
                Name      => "Delete",
                NameForID => "Delete",
                Action    => "AgentTicketMove;TicketID=$TicketID;DestQueue=Delete",
            },
            {
                Name      => "Spam",
                NameForID => "Spam",
                Action    => "AgentTicketMove;TicketID=$TicketID;DestQueue=Junk",
            },
        );

        # check ticket pre menu modules
        for my $MenuModulePre (@PreMenuModule) {

            # check pre menu module link
            $Self->True(
                $Selenium->find_element("//a[contains(\@href, \'Action=$MenuModulePre->{Action}' )]"),
                "Ticket pre menu $MenuModulePre->{Name} is found"
            );

            # check pre menu module name
            $Self->True(
                $Selenium->find_element( "#$MenuModulePre->{NameForID}$TicketID", 'css' ),
                "Ticket menu name $MenuModulePre->{Name} is found"
            );
        }

        # go to test created ticket zoom
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketZoom;TicketID=$TicketID");

        # create menu module test params
        my @MenuModule = (
            {
                Name      => "Back",
                NameForID => "Back",
                Action    => "AgentDashboard",
            },
            {
                Name      => "Lock",
                NameForID => "Lock",
                Action    => "AgentTicket"
            },
            {
                Name      => "History",
                NameForID => "History",
                Action    => "AgentTicketHistory",
            },
            {
                Name      => "Print",
                NameForID => "Print",
                Action    => "AgentTicketPrint",
            },
            {
                Name      => "Priority",
                NameForID => "Print",
                Action    => "AgentTicketPriority",
            },
            {
                Name      => "Free Fields",
                NameForID => "Free-Fields",
                Action    => "AgentTicketFreeText",
            },
            {
                Name      => "Link",
                NameForID => "Link",
                Action    => "AgentLinkObject",
            },
            {
                Name      => "Owner",
                NameForID => "Owner",
                Action    => "AgentTicketOwner",
            },
            {
                Name      => "Responsible",
                NameForID => "Responsible",
                Action    => "AgentTicketResponsible",
            },
            {
                Name      => "Customer",
                NameForID => "Customer",
                Action    => "AgentTicketCustomer",
            },
            {
                Name      => "Note",
                NameForID => "Note",
                Action    => "AgentTicketNote",
            },
            {
                Name      => "Phone Call Outbound",
                NameForID => "Phone-Call-Outbound",
                Action    => "AgentTicketPhoneOutbound",
            },
            {
                Name      => "Phone Call Inbound",
                NameForID => "Phone-Call-Inbound",
                Action    => "AgentTicketPhoneInbound",
            },
            {
                Name      => "E-Mail Outbound",
                NameForID => "E-Mail-Outbound",
                Action    => "AgentTicketEmailOutbound",
            },
            {
                Name      => "Merge",
                NameForID => "Merge",
                Action    => "AgentTicketMerge",
            },
            {
                Name      => "Pending",
                NameForID => "Pending",
                Action    => "AgentTicketPending",
            },
            {
                Name      => "Watch",
                NameForID => "Watch",
                Action    => "AgentTicketWatcher",
            },
            {
                Name      => "Close",
                NameForID => "Close",
                Action    => "AgentTicketClose",
            },
            {
                Name      => "Delete",
                NameForID => "Delete",
                Action    => "AgentTicketMove;TicketID=$TicketID;DestQueue=Delete",
            },
            {
                Name      => "Spam",
                NameForID => "Spam",
                Action    => "AgentTicketMove;TicketID=$TicketID;DestQueue=Junk",
            },
            {
                Name      => "People",
                NameForID => "People",
                Type      => "Cluster",
            },
            {
                Name      => "Communication",
                NameForID => "Communication",
                Type      => "Cluster",
            },
            {
                Name      => "Miscellaneous",
                NameForID => "Miscellaneous",
                Type      => "Cluster",
            },
        );

        # check ticket menu modules
        for my $ZoomMenuModule (@MenuModule) {

            if ( defined $ZoomMenuModule->{Type} && $ZoomMenuModule->{Type} eq 'Cluster' ) {

                # check menu module link
                $Self->True(
                    $Selenium->find_element( "li ul#nav-$ZoomMenuModule->{NameForID}-container", 'css' ),
                    "Ticket menu link $ZoomMenuModule->{Name} is found"
                );
            }
            else {

                # check menu module link
                $Self->True(
                    $Selenium->find_element("//a[contains(\@href, \'Action=$ZoomMenuModule->{Action}' )]"),
                    "Ticket menu link $ZoomMenuModule->{Name} is found"
                );
            }

            # check menu module name
            $Self->True(
                $Selenium->find_element( "li#nav-$ZoomMenuModule->{NameForID}", 'css' ),
                "Ticket menu name $ZoomMenuModule->{Name} is found"
            );
        }

        # delete created test tickets
        my $Success = $TicketObject->TicketDelete(
            TicketID => $TicketID,
            UserID   => $TestUserID,
        );
        $Self->True(
            $Success,
            "Delete ticket - $TicketID"
        );

        # make sure the cache is correct.
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
            Type => 'Ticket',
        );
    }
);

1;
