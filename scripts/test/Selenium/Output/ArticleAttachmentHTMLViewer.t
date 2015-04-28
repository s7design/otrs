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
                RestoreSystemConfiguration => 1,
                }
        );
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get sysconfig object
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

        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'PDF',
            Value => 0
        );

        # enable MIME-Viewer for PDF attachment
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'MIME-Viewer###application/pdf',
            Value => "pdftohtml -stdout -i",
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

        # create test company
        my $TestCustomerID    = $Helper->GetRandomID() . "CID";
        my $TestCompanyName   = "Company" . $Helper->GetRandomID();
        my $CustomerCompanyID = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyAdd(
            CustomerID             => $TestCustomerID,
            CustomerCompanyName    => $TestCompanyName,
            CustomerCompanyStreet  => '5201 Blue Lagoon Drive',
            CustomerCompanyZIP     => '33126',
            CustomerCompanyCity    => 'Miami',
            CustomerCompanyCountry => 'USA',
            CustomerCompanyURL     => 'http://www.example.org',
            CustomerCompanyComment => 'some comment',
            ValidID                => 1,
            UserID                 => $TestUserID,
        );

        # add test customer for testing
        my $TestCustomer = 'Customer' . $Helper->GetRandomID();
        my $UserLogin    = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
            Source         => 'CustomerUser',
            UserFirstname  => $TestCustomer,
            UserLastname   => $TestCustomer,
            UserCustomerID => $TestCustomerID,
            UserLogin      => $TestCustomer,
            UserEmail      => "$TestCustomer\@localhost.com",
            ValidID        => 1,
            UserID         => $TestUserID,
        );

        # create test phone ticket with PDF attachment
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');
        $Selenium->get("${ScriptAlias}index.pl?Action=AgentTicketPhone");

        # create test phone ticket
        my $AutoCompleteString = "\"$TestCustomer $TestCustomer\" <$TestCustomer\@localhost.com> ($TestCustomer)";
        my $AttachmentName     = "StdAttachment-Test1.pdf";
        my $Location           = $Kernel::OM->Get('Kernel::Config')->Get('Home')
            . "/scripts/test/sample/StdAttachment/$AttachmentName";
        $Selenium->find_element( "#FromCustomer", 'css' )->send_keys($TestCustomer);
        sleep 1;
        $Selenium->find_element("//*[text()='$AutoCompleteString']")->click();
        sleep 1;
        $Selenium->find_element( "#Dest option[value='4||Misc']", 'css' )->click();
        $Selenium->find_element( "#Subject",                      'css' )->send_keys("Selenium Ticket");
        $Selenium->find_element( "#RichText",                     'css' )->send_keys("Selenium body test");
        $Selenium->find_element( "#FileUpload",                   'css' )->send_keys($Location);

        # wait until attachment is upoading
        ACTIVESLEEP:
        for my $Second ( 1 .. 20 ) {
            if ( index( $Selenium->get_page_source(), $AttachmentName ) > -1 ) {
                last ACTIVESLEEP;
            }
            sleep 1;
        }

        $Selenium->find_element( "#Subject", 'css' )->submit();

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # search for new created ticket on AgentTicketZoom screen
        my %TicketIDs = $TicketObject->TicketSearch(
            Result         => 'HASH',
            Limit          => 1,
            CustomerUserID => $TestCustomer,
            UserID         => $TestUserID,
        );
        my $TicketNumber = (%TicketIDs)[1];
        my $TicketID     = (%TicketIDs)[0];

        my @ArticleIDs = $TicketObject->ArticleIndex(
            TicketID => (%TicketIDs)[0],
        );

        # wait until ticket is created
        ACTIVESLEEP:
        for my $Second ( 1 .. 20 ) {
            if ( index( $Selenium->get_page_source(), $TicketNumber ) > -1 ) {
                last ACTIVESLEEP;
            }
            sleep 1;
        }

        $Self->True(
            index( $Selenium->get_page_source(), $TicketNumber ) > -1,
            "Ticket with ticket id $TicketID is created"
        );

        # go to ticket zoom page of created test ticket
        $Selenium->find_element("//a[contains(\@href, \'Action=AgentTicketZoom' )]")->click();

        # check are there Downlaod and Viewer liks for test attachment
        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Download' )]"),
            "Download link for attachment is founded"
        );

        $Self->True(
            $Selenium->find_element("//a[contains(\@title, \'Viewer' )]"),
            "Viewer link for attachment is founded"
        );

        # check test attachment in MIME-Viwer
        $Selenium->find_element("//a[contains(\@title, \'Viewer' )]")->click();

        my $Handles = $Selenium->get_window_handles();
        $Selenium->switch_to_window( $Handles->[1] );

        # check expexted values in PDF test attachment
        for my $ExpextedValue (qw( OTRS.org TEST )) {
            $Self->True(
                index( $Selenium->get_page_source(), $ExpextedValue ) > -1,
                "Value is founded on screen - $ExpextedValue"
            );
        }
        $Selenium->close();

        # delete created test ticket
        my $Success = $TicketObject->TicketDelete(
            TicketID => $TicketID,
            UserID   => 1,
        );
        $Self->True(
            $Success,
            "Ticket with ticket id $TicketID is deleted"
        );

        # delete test customer company
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
        $Success = $DBObject->Do(
            SQL  => "DELETE FROM customer_company WHERE customer_id = ?",
            Bind => [ \$CustomerCompanyID ],
        );
        $Self->True(
            $Success,
            "Deleted CustomerCompany - $CustomerCompanyID",
        );

        # delete created test customer user
        $Success = $DBObject->Do(
            SQL  => "DELETE FROM customer_user WHERE login = ?",
            Bind => [ \$TestCustomer ],
        );
        $Self->True(
            $Success,
            "Deleted CustomerUser - $TestCustomer",
        );

        # make sure the cache is correct.
        for my $Cache (qw( Ticket CustomerUser CustomerCompany)) {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => $Cache );
        }

        }
);

1;
