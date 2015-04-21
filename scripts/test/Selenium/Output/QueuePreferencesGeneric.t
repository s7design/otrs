# --
# QueuePreferencesGeneric.t - frontend tests for QueuePreferencesGeneric
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
            Key   => 'QueuePreferences',
            Value => 1,
        );

        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        $Selenium->get("${ScriptAlias}index.pl?Action=AdminQueue");


            my $Data = $Selenium->screenshot();
            if ($Data ){
                $Data = MIME::Base64::decode_base64($Data);

                # This file should survive unit test scenario runs, so save it in a global directory.
                my ( $FH, $Filename ) = File::Temp::tempfile(
                    DIR    => '/tmp/',
                    SUFFIX => '.png',
                    UNLINK => 0,
                );
                close $FH;
                $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
                    Location => $Filename,
                    Content  => \$Data,
                );

                $Self->True(
                    1,
                    "Saved screenshot in file://$Filename",
                );
            }



        # add new queue
        $Selenium->find_element("//a[contains(\@href, \'Action=AdminQueue;Subaction=Add' )]")->click();

        # check add page, and especially included queue attribute Comment2
        for my $ID (
            qw(Name GroupID FollowUpID FollowUpLock SalutationID SystemAddressID SignatureID ValidID Comment2)
            )
        {
            my $Element = $Selenium->find_element( "#$ID", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();
        }

        # # create a real test queue
        # my $RandomQueueName = "Queue".$Helper->GetRandomID();

        # $Selenium->find_element( "#Name",                         'css' )->send_keys($RandomQueueName);
        # $Selenium->find_element( "#GroupID option[value='1']",    'css' )->click();
        # $Selenium->find_element( "#FollowUpID option[value='1']", 'css' )->click();
        # $Selenium->find_element( "#SalutationID option[value='1']",    'css' )->click();
        # $Selenium->find_element( "#SystemAddressID option[value='1']", 'css' )->click();
        # $Selenium->find_element( "#SignatureID option[value='1']",     'css' )->click();
        # $Selenium->find_element( "#ValidID option[value='1']",         'css' )->click();

        # # set included queue attribute Comment2
        # $Selenium->find_element( "#Comment2",                           'css' )->send_keys('QueuePreferences Comment2');
        # $Selenium->find_element( "#Name",                              'css' )->submit();

        # # check if test queue is created
        # $Self->True(
        #     index( $Selenium->get_page_source(), $RandomQueueName ) > -1,
        #     'New queue found on table'
        # );

        # # go to new queue again
        # $Selenium->find_element( $RandomQueueName, 'link_text' )->click();

        # # check queue value for Comment2
        # $Self->Is(
        #     $Selenium->find_element( '#Comment2', 'css' )->get_value(),
        #     'QueuePreferences Comment2',
        #     "#Comment2 stored value",
        # );

        # # update queue
        # my $UpdatedComment = "Updated comment for QueuePreferences Comment2";
        # my $UpdatedName = $RandomQueueName."-updated";
        # $Selenium->find_element( "#Name",                         'css' )->clear();
        # $Selenium->find_element( "#Name",                         'css' )->send_keys($UpdatedName);
        # $Selenium->find_element( "#Comment2", 'css' )->clear();
        # $Selenium->find_element( "#Comment2", 'css' )->send_keys($UpdatedComment);
        # $Selenium->find_element( "#Comment2", 'css' )->submit();

        # # check updated values
        # $Selenium->find_element( $UpdatedName, 'link_text' )->click();
        # $Self->Is(
        #     $Selenium->find_element( '#Name', 'css' )->get_value(),
        #     $UpdatedName,
        #     "#Name updated value",
        # );
        # $Self->Is(
        #     $Selenium->find_element( '#Comment2', 'css' )->get_value(),
        #     $UpdatedComment,
        #     "#Comment2 updated value",
        # );

        # # delete test queue
        # my $QueueID = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup(
        #     Queue => $UpdatedName,
        # );
        # my $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
        #     SQL => "DELETE FROM queue WHERE id = $QueueID",
        # );
        # $Self->True(
        #     $Success,
        #     "QueueDelete - $UpdatedName",
        # );

        # # Make sure the cache is correct.
        # $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        #     Type => 'Queue',
        # );
    }
);

1;
