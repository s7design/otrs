# --
# AdminUserGroup.t - frontend tests for AdminUserGroup
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

        # Make sure the cache is correct.
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'Group' );

        # create test group
        $Selenium->get("${ScriptAlias}index.pl?Action=AdminGroup");

        my $RandomID = $Helper->GetRandomID();

        # click 'add group' linK
        $Selenium->find_element("//button[\@value='Add'][\@type='submit']")->click();
        $Selenium->find_element( "#GroupName",                 'css' )->send_keys($RandomID);
        $Selenium->find_element( "#ValidID option[value='1']", 'css' )->click();
        $Selenium->find_element( "#GroupName",                 'css' )->submit();

        # give full read and write access to the tickets in test group for test user
        my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        $Selenium->find_element("//input[\@value='$UserID'][\@name='rw']")->click();
        $Selenium->find_element("//button[\@value='Submit'][\@type='submit']")->click();

        # check overview AdminUserGroup
        $Selenium->find_element( "div.Size1of2 #Users",  'css' );
        $Selenium->find_element( "div.Size1of2 #Groups", 'css' );

        # test filter for Agents using substring from created test agent
        $Selenium->find_element( "div.Content #FilterUsers", 'css' )->send_keys( substr $TestUserLogin, 4 );
        $Self->True(
            index( $Selenium->get_page_source(), $TestUserLogin ) > -1,
            "$TestUserLogin found on page",
        );

        # test filter for Groups using substring from created test group
        $Selenium->find_element( "div.Content #FilterGroups", 'css' )->send_keys( substr $RandomID, 4 );
        $Self->True(
            index( $Selenium->get_page_source(), $RandomID ) > -1,
            "$RandomID found on page",
        );

        # edit test group permission for test agent
        $Selenium->find_element( $RandomID, 'link_text' )->click();

        $Selenium->find_element("//input[\@value='$UserID'][\@name='rw']")->click();
        $Selenium->find_element("//input[\@value='$UserID'][\@name='ro']")->click();
        $Selenium->find_element("//input[\@value='$UserID'][\@name='note']")->click();
        $Selenium->find_element("//input[\@value='$UserID'][\@name='owner']")->click();

        $Selenium->find_element("//button[\@value='Submit'][\@type='submit']")->click();

        # check edited test group permissions
        $Selenium->find_element( $RandomID, 'link_text' )->click();

        $Self->Is(
            $Selenium->find_element("//input[\@value='$UserID'][\@name='move_into']")->is_selected(),
            1,
            "move_into permission for group $RandomID is enabled",
        );
        $Self->Is(
            $Selenium->find_element("//input[\@value='$UserID'][\@name='create']")->is_selected(),
            1,
            "create permission for group $RandomID is enabled",
        );
        $Self->Is(
            $Selenium->find_element("//input[\@value='$UserID'][\@name='rw']")->is_selected(),
            0,
            "rw permission for group $RandomID is disabled",
        );

        $Selenium->go_back();

        # edit test agent permission for test group
        my $TestGroupID = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
            Group => $RandomID,
        );

        my $TmpTestUserLogin = "$TestUserLogin ($TestUserLogin $TestUserLogin)";

        $Selenium->find_element( $TmpTestUserLogin, 'link_text' )->click();
        $Selenium->find_element("//input[\@value='$TestGroupID'][\@name='ro']")->click();
        $Selenium->find_element("//input[\@value='$TestGroupID'][\@name='note']")->click();

        $Selenium->find_element("//button[\@value='Submit'][\@type='submit']")->click();

        # check edited test agent permissions
        $Selenium->find_element( $TmpTestUserLogin, 'link_text' )->click();

        $Self->Is(
            $Selenium->find_element("//input[\@value='$TestGroupID'][\@name='ro']")->is_selected(),
            1,
            "ro permission for group $TestGroupID is enabled",
        );
        $Self->Is(
            $Selenium->find_element("//input[\@value='$TestGroupID'][\@name='note']")->is_selected(),
            1,
            "note permission for group $TestGroupID is enabled",
        );
        $Self->Is(
            $Selenium->find_element("//input[\@value='$TestGroupID'][\@name='rw']")->is_selected(),
            0,
            "rw permission for group $TestGroupID is disabled",
        );

        # Since there are no tickets that rely on our test group, we can remove them again
        # from the DB.
        if ($RandomID) {
            my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
            my $GroupID  = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
                Group => $RandomID,
            );

            my $Success = $DBObject->Do(
                SQL => "DELETE FROM group_user WHERE group_id = $GroupID",
            );
            if ($Success) {
                $Self->True(
                    $Success,
                    "GroupUserDelete - $RandomID",
                );
            }

            $RandomID = $DBObject->Quote($RandomID);
            $Success  = $DBObject->Do(
                SQL  => "DELETE FROM groups WHERE name = ?",
                Bind => [ \$RandomID ],
            );
            $Self->True(
                $Success,
                "GroupDelete - $RandomID",
            );
        }

        # Make sure the cache is correct.
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'Group' );

        }

);

1;
