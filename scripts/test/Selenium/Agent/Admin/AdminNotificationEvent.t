# --
# AdminNotificationEvent.t - frontend tests for AdminNotificationEvent
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
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');

my $Selenium = Kernel::System::UnitTest::Selenium->new(
    Verbose => 1,
);

$Selenium->RunTest(
    sub {

        my $Helper = Kernel::System::UnitTest::Helper->new(
            RestoreSystemConfiguration => 1,
        );

        # do not check RichText
        $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0
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

        $Selenium->get("${ScriptAlias}index.pl?Action=AdminNotificationEvent");

        # check overview screen
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );

        # click "Add notification"
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Add' )]")->click();

        # check add NotificationEvent screen
        for my $ID (
            qw(Name Comment ValidID Events Subject RichText)
            )
        {
            my $Element = $Selenium->find_element( "#$ID", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();
        }

        # toggle Ticket filter widget
        $Selenium->find_element("//a[contains(\@aria-controls, \'Core_UI_AutogeneratedID_1')]")->click();

        # toggle Article filter (Only for ArticleCreate and ArticleSend event) widget
        $Selenium->find_element("//a[contains(\@aria-controls, \'Core_UI_AutogeneratedID_2')]")->click();

        # create test NotificationEvent
        my $NotifEventRandomID = "notifevent" . $Helper->GetRandomID();
        my $NotifEventText     = "Selenium NotificationEvent test";

        $Selenium->find_element( "#Name",                                 'css' )->send_keys($NotifEventRandomID);
        $Selenium->find_element( "#Comment",                              'css' )->send_keys($NotifEventText);
        $Selenium->find_element( "#Events option[value='ArticleCreate']", 'css' )->click();
        $Selenium->find_element( "#Subject",                              'css' )->send_keys($NotifEventText);
        $Selenium->find_element( "#RichText",                             'css' )->send_keys($NotifEventText);
        $Selenium->find_element( "#ArticleSubjectMatch",                  'css' )->send_keys($NotifEventText);
        $Selenium->find_element( "#Name",                                 'css' )->submit();

        # check if test NotificationEvent show on AdminNotificationEvent screen
        $Self->True(
            index( $Selenium->get_page_source(), $NotifEventRandomID ) > -1,
            "$NotifEventRandomID NotificaionEvent found on page",
        );

        # check test NotificationEvent values
        $Selenium->find_element( $NotifEventRandomID, 'link_text' )->click();

        $Self->Is(
            $Selenium->find_element( '#Name', 'css' )->get_value(),
            $NotifEventRandomID,
            "#Name stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#Comment', 'css' )->get_value(),
            $NotifEventText,
            "#Comment stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#Subject', 'css' )->get_value(),
            $NotifEventText,
            "#Subject stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#RichText', 'css' )->get_value(),
            $NotifEventText,
            "#RichText stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#ArticleSubjectMatch', 'css' )->get_value(),
            $NotifEventText,
            "#ArticleSubjectMatch stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#ValidID', 'css' )->get_value(),
            1,
            "#ValidID stored value",
        );

        # edit test NotificationEvent and set it to invalid
        my $EditNotifEventText = "Selenium edited NotificationEvent test";

        # toggle Article filter (Only for ArticleCreate and ArticleSend event) widget
        $Selenium->find_element("//a[contains(\@aria-controls, \'Core_UI_AutogeneratedID_2')]")->click();

        $Selenium->find_element( "#Comment",                   'css' )->clear();
        $Selenium->find_element( "#RichText",                  'css' )->clear();
        $Selenium->find_element( "#RichText",                  'css' )->send_keys($EditNotifEventText);
        $Selenium->find_element( "#ArticleSubjectMatch",       'css' )->clear();
        $Selenium->find_element( "#ArticleBodyMatch",          'css' )->send_keys($EditNotifEventText);
        $Selenium->find_element( "#ValidID option[value='2']", 'css' )->click();
        $Selenium->find_element( "#Name",                      'css' )->submit();

        # check edited NotifcationEvent values
        $Selenium->find_element( $NotifEventRandomID, 'link_text' )->click();

        $Self->Is(
            $Selenium->find_element( '#Comment', 'css' )->get_value(),
            "",
            "#Comment updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#RichText', 'css' )->get_value(),
            $EditNotifEventText,
            "#RichText updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#ArticleSubjectMatch', 'css' )->get_value(),
            "",
            "#ArticleSubjectMatch updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#ArticleBodyMatch', 'css' )->get_value(),
            $EditNotifEventText,
            "#ArticleBodyMatch updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#ValidID', 'css' )->get_value(),
            2,
            "#ValidID updated value",
        );

        $Selenium->go_back();

        # get NotificationEventID
        my %NotifEventID = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationGet(
            Name => $NotifEventRandomID
        );

        # delete test SLA with delete button
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Delete;ID=$NotifEventID{ID}' )]")->click();

        }

);

1;
