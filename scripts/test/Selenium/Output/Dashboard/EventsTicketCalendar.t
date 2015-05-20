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

use Kernel::System::VariableCheck (qw(IsHashRefWithData));

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

        # get SysConfig object
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        # do not check RichText
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0
        );

        # do not check service and type
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Service',
            Value => 0
        );
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Type',
            Value => 0
        );

        # disable all dashboard plugins
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get('DashboardBackend');
        $SysConfigObject->ConfigItemUpdate(
            Valid => 0,
            Key   => 'DashboardBackend',
            Value => \%$Config,
        );

        # enable EventsTicketCalendar and set it to load as default plugin
        my %EventsTicketCalendarSysConfig = (
            Block    => 'ContentLarge',
            CacheTTL => 0,
            Default  => 1,
            Group    => '',
            Module   => 'Kernel::Output::HTML::Dashboard::EventsTicketCalendar',
            Title    => 'Events Ticket Calendar',
        );
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'DashboardBackend###0280-DashboardEventsTicketCalendar',
            Value => \%EventsTicketCalendarSysConfig,
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

        # get test user ID
        my $TestUserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # get dynamic field object
        my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

        # check for event ticket calendar dynamic fields, if there are none create them
        my @DynamicFieldIDs;
        for my $DynamicFieldName (qw(TicketCalendarStartTime TicketCalendarEndTime)) {
            my $DynamicFieldExist = $DynamicFieldObject->DynamicFieldGet(
                Name => $DynamicFieldName,
            );
            if ( !IsHashRefWithData($DynamicFieldExist) ) {
                my $DynamicFieldID = $DynamicFieldObject->DynamicFieldAdd(
                    Name       => $DynamicFieldName,
                    Label      => $DynamicFieldName,
                    FieldOrder => 9991,
                    FieldType  => 'DateTime',
                    ObjectType => 'Ticket',
                    Config     => {
                        DefaultValue  => 0,
                        YearsInFuture => 0,
                        YearsInPast   => 0,
                        YearsPeriod   => 0,
                    },
                    ValidID => 1,
                    UserID  => $TestUserID,
                );
                $Self->True(
                    $DynamicFieldID,
                    "Dynamic field $DynamicFieldName - ID $DynamicFieldID - created",
                );

                push @DynamicFieldIDs, $DynamicFieldID;
            }
        }

        # get dynamic field sysconfig params
        my %SysConfigDynamicField = (
            TicketCalendarEndTime   => 1,
            TicketCalendarStartTime => 1,
        );

        # enable created test calendar dynamic fields for phone ticket
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Frontend::AgentTicketPhone###DynamicField',
            Value => \%SysConfigDynamicField,
        );

        # get customer user object
        my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

        # create customer user
        my $TestCustomerUser   = "SeleniumCustomer" . rand int(1000);
        my $TestCustomerUserID = $CustomerUserObject->CustomerUserAdd(
            Source         => 'CustomerUser',
            UserFirstname  => $TestCustomerUser,
            UserLastname   => $TestCustomerUser,
            UserCustomerID => $TestCustomerUser,
            UserLogin      => $TestCustomerUser,
            UserEmail      => $TestCustomerUser . "\@localhost.com",
            ValidID        => 1,
            UserID         => $TestUserID,
        );
        $Self->True(
            $TestCustomerUserID,
            "Customer user $TestCustomerUser - created"
        );

        # create test ticket that will be shown on EventsTicketCalendar
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');
        $Selenium->get("${ScriptAlias}index.pl?Action=AgentTicketPhone");

        my $AutoCompleteString
            = "\"$TestCustomerUser $TestCustomerUser\" <$TestCustomerUser\@localhost.com> ($TestCustomerUser)";
        my $TicketSubject = "Selenium Ticket";
        my $TicketBody    = "Selenium body test";
        $Selenium->find_element( "#FromCustomer", 'css' )->send_keys($TestCustomerUser);
        $Selenium->WaitFor( JavaScript => 'return $("li.ui-menu-item:visible").length' );

        $Selenium->find_element("//*[text()='$AutoCompleteString']")->click();
        $Selenium->find_element( "#Dest option[value='2||Raw']",              'css' )->click();
        $Selenium->find_element( "#Subject",                                  'css' )->send_keys($TicketSubject);
        $Selenium->find_element( "#RichText",                                 'css' )->send_keys($TicketBody);
        $Selenium->find_element( "#DynamicField_TicketCalendarEndTimeUsed",   'css' )->click();
        $Selenium->find_element( "#DynamicField_TicketCalendarStartTimeUsed", 'css' )->click();
        $Selenium->find_element( "#Subject",                                  'css' )->submit();

        # get test created ticket ID
        my %TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
            Result         => 'HASH',
            Limit          => 1,
            CustomerUserID => $TestCustomerUserID,
        );
        my $TicketID = (%TicketIDs)[0];

        # go to dashboard screen
        $Selenium->get("${ScriptAlias}index.pl?Action=AgentDashboard");

        # test if link to test created ticket is available when only EventsTicketCalendar is valid plugin
        $Self->True(
            index( $Selenium->get_page_source(), "Action=AgentTicketZoom;TicketID=$TicketID" ) > -1,
            "Link to created test ticket ID - $TicketID - available on EventsTicketCalendar plugin",
        );

        # delete created test ticket
        my $Success = $Kernel::OM->Get('Kernel::System::Ticket')->TicketDelete(
            TicketID => $TicketID,
            UserID   => $TestUserID,
        );
        $Self->True(
            $Success,
            "Ticket with ticket id $TicketID is deleted"
        );

        # delete created test customer user
        $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => "DELETE FROM customer_user WHERE customer_id = ?",
            Bind => [ \$TestCustomerUserID ],
        );
        $Self->True(
            $Success,
            "Deleted CustomerUser - $TestCustomerUserID",
        );

        # delete created test calendar dynamic fields
        for my $DynamicFieldDelete (@DynamicFieldIDs) {
            $Success = $DynamicFieldObject->DynamicFieldDelete(
                ID     => $DynamicFieldDelete,
                UserID => $TestUserID,
            );
            $Self->True(
                $Success,
                "Dynamic field - ID $DynamicFieldDelete - deleted",
            );
        }

        # make sure the cache is correct.
        for my $Cache (
            qw (Ticket CustomerUser DynamicField)
            )
        {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $Cache,
            );
        }

    }
);

1;
