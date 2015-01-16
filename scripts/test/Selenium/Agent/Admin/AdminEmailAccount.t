# --
# AdminEmailAccount.t - frontend tests for AdminEmailAccount
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
my $ConfigObject      = $Kernel::OM->Get('Kernel::Config');
my $MailAccountObject = $Kernel::OM->Get('Kernel::System::MailAccount');
$Kernel::OM->Get('Kernel::System::DB');

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

        # add test mail account
        my $MailAccountAdd = $MailAccountObject->MailAccountAdd(
            Login         => 'mail',
            Password      => 'SomePassword',
            Host          => 'pop3.example.com',
            Type          => 'POP3',
            ValidID       => 1,
            Trusted       => 0,
            IMAPFolder    => 'Foo',
            DispatchingBy => 'Queue',
            QueueID       => 1,
            UserID        => 1,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        $Selenium->get("${ScriptAlias}index.pl?Action=AdminMailAccount");

        # check AdminMailAccount screen
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );

        # check if test mail account is present
        my $TestMailHost = "pop3.example.com / mail";
        $Self->True(
            index( $Selenium->get_page_source(), $TestMailHost ) > -1,
            "$TestMailHost found on page",
        );

        # check add mail account
        $Selenium->find_element("//a[contains(\@href, \'Subaction=AddNew' )]")->click();

        for my $ID (
            qw(TypeAdd LoginAdd PasswordAdd HostAdd IMAPFolder Trusted DispatchingBy ValidID Comment)
            )
        {
            my $Element = $Selenium->find_element( "#$ID", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();
        }

        # return to previous screen
        $Selenium->get("${ScriptAlias}index.pl?Action=AdminMailAccount");

        # edit test mail account and set it to invalid
        $Selenium->find_element( $TestMailHost, 'link_text' )->click();

        $Selenium->find_element( "#LoginEdit",                 'css' )->send_keys("edit");
        $Selenium->find_element( "#ValidID option[value='2']", 'css' )->click();
        $Selenium->find_element( "#LoginEdit",                 'css' )->submit();

        # check for edited mail account
        my $TestMailHostEdit = "pop3.example.com / mailedit";
        $Self->True(
            index( $Selenium->get_page_source(), $TestMailHostEdit ) > -1,
            "$TestMailHostEdit found on page",
        );

        # delete test mail account
        my %MailAccount = $MailAccountObject->MailAccountGet(
            ID => $MailAccountAdd,
        );

        $Selenium->find_element("//a[contains(\@href, \'Subaction=Delete;ID=$MailAccount{ID}' )]")->click();

        }

);

1;
