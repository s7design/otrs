# --
# AdminNotificationEventEncode.t - frontend tests for AdminNotificationEventEncode
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

our $ObjectManagerDisabled = 1;

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

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

        # do not check RichText
        $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 1
        );

        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get notification that ends with &nbsp;
        my $NotifEventRandomID = "notifevent" . $Helper->GetRandomID();
        my $NotifEventText     = "Selenium NotificationEvent test";

        # Add NotificationEvent
        my $NotificationID = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationAdd(
            Name    => $NotifEventRandomID,
            Subject => $NotifEventText,
            Body    => "Test notification&nbsp;",
            Type    => 'text/html',
            Charset => 'utf-8',
            Comment => 'Just something modified for test',
            Data    => {
                Events     => [ 'TicketCreate', ],
                QueueID    => [ '1', '2', '3', '4', ],
                Recipients => [ 'Customer', ],
            },
            ValidID => 1,
            UserID  => 1,
        );

        $Self->True(
            $NotificationID,
            "Test notification is created - $NotifEventRandomID ",
        );

        my $TestCustomerUserLogin = $Helper->TestCustomerUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        my $TicketID = $Kernel::OM->Get('Kernel::System::Ticket')->TicketCreate(
            Title        => 'Some Ticket_Title',
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
            "Test ticket is created - $TicketID ",
        );

        # get NotificationEventID
        my %NotifEventID = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationGet(
            Name => $NotifEventRandomID
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # go to SysLog screen
        $Selenium->get("${ScriptAlias}index.pl?Action=AdminLog");

        print "There is error in SysLog if PosgreSQL is used!!!!!! \n";

=start
        $Self->True(
            index( $Selenium->get_page_source(), "ERROR:  invalid byte sequence for encoding \"UTF8\": 0xa0" ) > -1,
            "ERROR log found on page",
        );


        my $Success = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationUpdate(
            ID      => $NotificationID,
            Name    => $NotifEventRandomID,
            Subject => $NotifEventText,
            Body    => "Test notification&nbsp;",
            Type    => 'text/html',
            Charset => 'utf-8',
            Comment => 'Just something modified for test',
            Data    => {
            },
            ValidID => 2,
            UserID => 1,
        );

        $Self->True(
            $Success,
            "Test notification is set to invalid - $NotifEventRandomID ",
        );
=cut

        }

);

1;
