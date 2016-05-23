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

my $CheckBreadcrumb = sub {

    my %Param = @_;

    my $BreadcrumbText = $Param{BreadcrumbText} || '';
    my $Count = 1;

    for my $BreadcrumbText ( 'System Email Addresses Management', $BreadcrumbText ) {
        $Self->Is(
            $Selenium->execute_script("return \$('.BreadCrumb li:eq($Count)').text().trim()"),
            $BreadcrumbText,
            "Breadcrumb text '$BreadcrumbText' is found on screen"
        );

        $Count++;
    }
};

$Selenium->RunTest(
    sub {

        # get queue object
        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # disable check email address
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'CheckEmailAddresses',
            Value => 0,
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get test user ID
        my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # add test queue
        my $QueueName = "queue" . $Helper->GetRandomID();
        my $QueueID   = $QueueObject->QueueAdd(
            Name            => $QueueName,
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            UserID          => $UserID,
            Comment         => 'Selenium Test Queue',
        );
        $Self->True(
            $QueueID,
            "Created Queue - $QueueName",
        );

        # get script alias
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # navigate to AdminSystemAddress screen
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminSystemAddress");

        # check overview AdminSystemAddress screen
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );

        # check breadcrumb on Overview screen
        $Self->True(
            $Selenium->find_element( '.BreadCrumb', 'css' ),
            "Breadcrumb is found on Overview screen.",
        );

        # click 'Add system address'
        $Selenium->find_element("//a[contains(\@href, \'Action=AdminSystemAddress;Subaction=Add')]")->VerifiedClick();

        # check add new SystemAddress screen
        for my $ID (
            qw(Name Realname QueueID ValidID Comment)
            )
        {
            my $Element = $Selenium->find_element( "#$ID", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();
        }

        # check breadcrumb on Add screen
        $CheckBreadcrumb->( BreadcrumbText => 'Add System Email Address' );

        # check client side validation
        $Selenium->find_element( "#Name", 'css' )->clear();
        $Selenium->find_element( "#Name", 'css' )->VerifiedSubmit();
        $Self->Is(
            $Selenium->execute_script(
                "return \$('#Name').hasClass('Error')"
            ),
            '1',
            'Client side validation correctly detected missing input value',
        );

        # create test system address
        my $SysAddRandom  = 'sysadd' . $Helper->GetRandomID() . '@localhost.com';
        my $SysAddComment = "Selenium test SystemAddress";

        $Selenium->find_element( "#Name",     'css' )->send_keys($SysAddRandom);
        $Selenium->find_element( "#Realname", 'css' )->send_keys($SysAddRandom);
        $Selenium->execute_script("\$('#QueueID').val('$QueueID').trigger('redraw.InputField').trigger('change');");
        $Selenium->find_element( "#Comment", 'css' )->send_keys($SysAddComment);
        $Selenium->find_element( "#Name",    'css' )->VerifiedSubmit();

        # check for created test SystemAddress
        $Self->True(
            index( $Selenium->get_page_source(), $SysAddRandom ) > -1,
            "$SysAddRandom found on page",
        );

        # go to the new test SystemAddress and check values
        $Selenium->find_element( $SysAddRandom, 'link_text' )->VerifiedClick();
        $Self->Is(
            $Selenium->find_element( '#Name', 'css' )->get_value(),
            $SysAddRandom,
            "#Name stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#Realname', 'css' )->get_value(),
            $SysAddRandom,
            "#Realname stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#QueueID', 'css' )->get_value(),
            $QueueID,
            "#QueueID stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#ValidID', 'css' )->get_value(),
            1,
            "#ValidID stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#Comment', 'css' )->get_value(),
            $SysAddComment,
            "#Comment stored value",
        );

        # check breadcrumb on Edit screen
        $CheckBreadcrumb->( BreadcrumbText => 'Edit System Email Address: ' . $SysAddRandom );

        # navigate to AdminSystemAddress screen
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminSystemAddress");

        # get system address ID
        my $SysAddRandomID = $Selenium->execute_script(
            "return \$('tr.MasterAction td a:contains($SysAddRandom)').attr('href').split('ID=')[1]"
        );

        # update queue with SysAddRandomID
        my $Success = $QueueObject->QueueUpdate(
            QueueID         => $QueueID,
            Name            => $QueueName,
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => $SysAddRandomID,
            SalutationID    => 1,
            SignatureID     => 1,
            UserID          => 1,
            FollowUpID      => 1,
        );
        $Self->True(
            $Success,
            "QueueID $QueueID is updated successfully - connected with SystemAddressID $SysAddRandomID",
        );

        # navigate to screen for change system address
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminSystemAddress;Subaction=Change;ID=$SysAddRandomID");

        # try to set system address ID to invalid
        $Selenium->execute_script("\$('#ValidID').val('2').trigger('redraw.InputField').trigger('change')");
        $Selenium->find_element( "button[value='Save'][type='submit']", 'css' )->VerifiedClick();
        $Self->True(
            index(
                $Selenium->get_page_source(),
                'System e-mail address is a parameter in some queue(s) and it should not be changed!'
                ) > -1,
            "'$SysAddRandom' can't be set to invalid because it is parameter in some queue(s)",
        );

        # update queue back to the system address ID = 1
        $Success = $QueueObject->QueueUpdate(
            QueueID         => $QueueID,
            Name            => $QueueName,
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            UserID          => 1,
            FollowUpID      => 1,
        );
        $Self->True(
            $Success,
            "QueueID $QueueID is updated successfully",
        );

        # navigate to screen for change system address
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminSystemAddress;Subaction=Change;ID=$SysAddRandomID");

        # edit test SystemAddress and set it to invalid
        $Selenium->find_element( "#Realname", 'css' )->send_keys(" Edited");
        $Selenium->execute_script("\$('#ValidID').val('2').trigger('redraw.InputField').trigger('change');");
        $Selenium->find_element( "#Comment", 'css' )->clear();
        $Selenium->find_element( "#Name",    'css' )->VerifiedSubmit();

        # check class of invalid SystemAddress in the overview table
        $Self->True(
            $Selenium->execute_script(
                "return \$('tr.Invalid td a:contains($SysAddRandom)').length"
            ),
            "There is a class 'Invalid' for test SystemAddress",
        );

        # check edited test SystemAddress values
        $Selenium->find_element( $SysAddRandom, 'link_text' )->VerifiedClick();

        $Self->Is(
            $Selenium->find_element( '#Realname', 'css' )->get_value(),
            $SysAddRandom . " Edited",
            "#Realname updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#ValidID', 'css' )->get_value(),
            2,
            "#ValidID updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#Comment', 'css' )->get_value(),
            "",
            "#Comment updated value",
        );

        # get DB object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # cleanup
        # delete test system address
        $Success = $DBObject->Do(
            SQL => "DELETE FROM system_address WHERE value0 = \'$SysAddRandom\'",
        );
        $Self->True(
            $Success,
            "SystemAddress $SysAddRandom is deleted",
        );

        # delete test queue
        $Success = $DBObject->Do(
            SQL => "DELETE FROM queue WHERE id = \'$QueueID\'",
        );
        $Self->True(
            $Success,
            "QueueID $QueueID is deleted",
        );

        # make sure cache is correct
        for my $Cache (qw (Queue SystemAddress))
        {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $Cache,
            );
        }

    }

);

1;
