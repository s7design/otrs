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

        # get needed objects
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::UnitTest::Helper' => {
                RestoreSystemConfiguration => 1,
            },
        );
        my $Helper          = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        # do not check RichText
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0,
        );

        # enable spellchecker
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'SpellChecker',
            Value => 1,
        );

        # set aspell as spellchecker bin
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'SpellCheckerBin',
            Value => '/usr/bin/aspell',
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

        # get script alias
        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        # navigate to AgentTicketPhone screen
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AgentTicketPhone");

        # input wrong spelled words
        my $WrongSpelledString = "Thiis is wrng spelled strng";
        $Selenium->find_element( "#RichText", 'css' )->send_keys($WrongSpelledString);

        # click on Spell Check
        $Selenium->find_element( "#OptionSpellCheck", 'css' )->click();

        # switch to spellcheck iframe
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("iframe").length' );
        $Selenium->switch_to_frame( $Selenium->find_element( ".SpellCheck", 'css' ) );

        # verify wrong spelled string
        $Self->Is(
            $Selenium->find_element( "#Body", 'css' )->get_text(),
            $WrongSpelledString,
            "Wrong spelled string is found"
        );

        # correct wrong spelled string
        $Selenium->find_element( "#ChangeWord1", 'css' )->click();
        $Selenium->find_element( "#ChangeWord2", 'css' )->click();
        $Selenium->find_element( "#ChangeWord3", 'css' )->click();

        $Selenium->find_element("//button[\@value='Apply these changes']")->VerifiedClick();

        # verify text is corrected in iframe
        my $ChangedSpelledString = "Th's is Wang spelled sarong";
        $Self->Is(
            $Selenium->find_element( "#Body", 'css' )->get_text(),
            $ChangedSpelledString,
            "Changed spelled string is found"
        );

        # submit spellchecked string
        $Selenium->find_element( "#Apply", 'css' )->click();

        # return back to AgentTicketPhone screen
        my $Handles = $Selenium->get_window_handles();
        $Selenium->switch_to_window( $Handles->[0] );

        # verify spellchecked string in RichText body
        $Self->Is(
            $Selenium->find_element( "#RichText", 'css' )->get_value(),
            $ChangedSpelledString,
            "Changed spelled string is found in AgentTicketPhone screen"
        );

    }

);

1;
