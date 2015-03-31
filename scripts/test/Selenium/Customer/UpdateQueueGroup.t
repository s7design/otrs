# --
# UpdateQueueGroup.t - UpdateQueueGroup tests update 'To' in CustomerTicketMessage on Add/Update Group
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
                RestoreSystemConfiguration => 0,
                }
        );
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # create and login test customer
        my $TestUserLogin = $Helper->TestCustomerUserCreate(
        ) || die "Did not get test user";
        $Selenium->Login(
            Type     => 'Customer',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # add test queue in group users
        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
        my $QueueName   = "Q" . $Helper->GetRandomID();
        my $QueueID     = $QueueObject->QueueAdd(
            Name            => $QueueName,
            ValidID         => 1,
            GroupID         => 1,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            UserID          => 1,
            Comment         => 'Selenium test queue',
        );

        # get test queue ID
        my %Queue = $QueueObject->QueueGet(
            Name => $QueueName,
        );

        # click on 'Create your first ticket'
        $Selenium->find_element( ".Button", 'css' )->click();

        # verify that test queue is available for users group
        $Self->True(
            $Selenium->find_element( "#Dest option[value='$QueueID||$QueueName']", 'css' ),
            "$Queue{Name} is available to select"
        );

        # create test group
        my $GroupName   = "G" . $Helper->GetRandomID();
        my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
        my $GroupID     = $GroupObject->GroupAdd(
            Name    => $GroupName,
            ValidID => 1,
            UserID  => 1,
        );

        # add test queue to test group
        my $QueueUpdateID = $QueueObject->QueueUpdate(
            QueueID         => $QueueID,
            Name            => $QueueName,
            GroupID         => $GroupID,
            SystemAddressID => 1,
            SalutationID    => 1,
            SignatureID     => 1,
            FollowUpID      => 1,
            UserID          => 1,
            ValidID         => 1,
        );

        # get cache object
        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        # refresh page
        $Selenium->refresh();

        # check if test queue is available to select
        my $Success;
        eval {
            $Success = index( $Selenium->get_page_source(), $QueueName ),
        };
        if ( $Success > -1 ) {
            print "\nPatch is success $QueueName is available to select with new group $GroupName\n\n";
        }
        else {
            print "\n$Queue{Name} is no longer available to select with new group $GroupName\n\n";

            # clear cache
            print "\nClearing cache\n\n";
            $CacheObject->CleanUp(
                Type => 'CustomerGroup',
            );

            # refresh page
            $Selenium->refresh();

            # verify that test queue is now available for test group after clearing cache
            $Self->True(
                $Selenium->find_element( "#Dest option[value='$QueueID||$QueueName']", 'css' ),
                "$Queue{Name} is available to select after clearing cache"
            );
        }

        # update group
        print "\nUpdating group to invalid status\n\n";
        my $GroupUpdate = $GroupObject->GroupUpdate(
            ID      => $GroupID,
            Name    => $GroupName,
            ValidID => 2,
            UserID  => 1,
        );

        # refresh page
        $Selenium->refresh();

        # check if test queue is available to select
        eval {
            $Success = index( $Selenium->get_page_source(), $QueueName ),
        };
        if ( $Success > -1 ) {
            print "\n$QueueName is available to select with invalid group $GroupName\n\n";

            # clear cache
            print "Clearing cache\n\n";
            $CacheObject->CleanUp(
                Type => 'CustomerGroup',
            );

            # refresh page
            $Selenium->refresh();

            # check after clearing cache for test queue with invalid test group
            $Self->False(
                index( $Selenium->get_page_source(), $QueueName ) > -1,
                "$QueueName is not available to select with invalid group $GroupName after clearing cache",
            );
        }
        else {
            print "\nPatch is success, $QueueName is not available to select with invalid group $GroupName\n\n";
        }
        }
);
1;
