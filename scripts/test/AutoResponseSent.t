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

# get needed objects
my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
my $QueueObject        = $Kernel::OM->Get('Kernel::System::Queue');
my $AutoResponseObject = $Kernel::OM->Get('Kernel::System::AutoResponse');
my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
my $TestEmailObject    = $Kernel::OM->Get('Kernel::System::Email::Test');

# use test email backend
my $Success = $ConfigObject->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::Test',
);
$Self->True(
    $Success,
    "Set test backend Email - true",
);

# get test data
my @Tests = (
    {
        Subject            => 'AutoResponse Reply',
        AutoResponseTypeID => 1,
        AutoResponseType   => 'auto reply',
        TicketState        => 'open',
        ArticleType        => 'phone',
        ArticleBody        => 'UnitTest body',
        OrigHeaderBody     => 'UnitTest body',
        AutoResponseBody   => 'UnitTest AutoResponse reply',
    },
    {
        Subject            => 'AutoResponse Follow Up',
        FollowUpID         => 1,                                   # Queue follow up option 'possible'
        AutoResponseTypeID => 3,
        AutoResponseType   => 'auto follow up',
        TicketState        => 'open',
        ArticleType        => 'webrequest',
        ArticleBody        => 'UnitTest body',
        OrigHeaderBody     => 'UnitTest body',
        AutoResponseBody   => 'UnitTest AutoResponse follow up',
    },
    {
        Subject            => 'AutoResponse Reject',
        FollowUpID         => 2,                                   # Queue follow up option 'rejected'
        AutoResponseTypeID => 2,
        AutoResponseType   => 'auto reject',
        TicketState        => 'closed successful',
        ArticleType        => 'webrequest',
        ArticleBody        => 'UnitTest body',
        OrigHeaderBody     => 'UnitTest body',
        AutoResponseBody   => 'UnitTest AutoResponse reject',
    },
    {
        Subject            => 'AutoResponse Reply/New Ticket',
        FollowUpID         => 3,                                            # Queue follow up option 'new ticket'
        AutoResponseTypeID => 4,
        AutoResponseType   => 'auto reply/new ticket',
        TicketState        => 'closed successful',
        ArticleType        => 'webrequest',
        ArticleBody        => 'UnitTest body',
        OrigHeaderBody     => 'UnitTest body',
        AutoResponseBody   => 'UnitTest AutoResponse reply / new ticket',
    },
    {
        Subject            => 'AutoResponse Remove',
        AutoResponseTypeID => 5,
        AutoResponseType   => 'auto remove',
        TicketState        => 'removed',
        ArticleType        => 'webrequest',
        ArticleBody        => 'UnitTest body',
        OrigHeaderBody     => 'UnitTest body',
        AutoResponseBody   => 'UnitTest AutoResponse remove',
    },

    # test auto response <OTRS_CUSTOMER_BODY[n]> tag for HTML article see bug #9837
    {
        Subject            => 'АutoResponse OTRS_CUSTOMER Body and Subject tags in HTML article',
        AutoResponseTypeID => 1,
        AutoResponseType   => 'auto reply',
        TicketState        => 'open',
        ArticleType        => 'webrequest',
        ArticleBody =>
            '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/></head>
                                <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;"><a href="http://www.localhost.com" target="_blank">This is test text with link</a>
                               </body></html>',
        OrigHeaderBody => '[1]This is test text with link

[1] http://www.localhost.com
',
        AutoResponseBody    => '<OTRS_CUSTOMER_SUBJECT[30]> <OTRS_CUSTOMER_BODY[10]>',
        AutoResponseWithTag => 1,
    },
);

# run test
my @QueueIDs;
my @TicketIDs;
my @AutoResponseIDs;
my $Count = 1;
for my $Test (@Tests) {

    # clean up test email backend
    $Success = $TestEmailObject->CleanUp();
    $Self->True(
        $Success,
        "Test $Count : Test backend Email initial cleanup",
    );
    $Self->IsDeeply(
        $TestEmailObject->EmailsGet(),
        [],
        "Test $Count : Test backend Email empty after initial cleanup",
    );

    # create test queue
    my $QueueName = 'Queue' . int( rand(1000000) );
    my $QueueID   = $QueueObject->QueueAdd(
        Name            => $QueueName,
        ValidID         => 1,
        GroupID         => 1,
        SystemAddressID => 1,
        FollowUpID      => $Test->{FollowUpID},
        SalutationID    => 1,
        SignatureID     => 1,
        Comment         => 'UnitTest queue',
        UserID          => 1,
    );
    $Self->True(
        $QueueID,
        "Test $Count : QueueAdd() - QueueID $QueueID",
    );
    push @QueueIDs, $QueueID;

    # create test auto-response
    my $AutoResponseName = 'AutoResponse' . int( rand(1000000) );
    my $AutoResponseID   = $AutoResponseObject->AutoResponseAdd(
        Name        => $AutoResponseName,
        ValidID     => 1,
        Subject     => $Test->{Subject},
        Response    => $Test->{AutoResponseBody},
        ContentType => 'text/plain',
        AddressID   => 1,
        TypeID      => $Test->{AutoResponseTypeID},
        UserID      => 1,
    );
    $Self->True(
        $AutoResponseID,
        "Test $Count : AutoResponseAdd() - AutoResponseID $AutoResponseID",
    );
    push @AutoResponseIDs, $AutoResponseID;

    # assigns test auto-responses to a test queue
    my $AutoResponseQueue = $AutoResponseObject->AutoResponseQueue(
        QueueID         => $QueueID,
        AutoResponseIDs => [$AutoResponseID],
        UserID          => 1,
    );
    $Self->True(
        $AutoResponseQueue,
        "Test $Count : AutoResponseQueue() - added relation",
    );

    # create test ticket
    my $TicketIDOne = $TicketObject->TicketCreate(
        Title        => 'UnitTest ticket one',
        QueueID      => $QueueID,
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'open',
        CustomerID   => '12345',
        CustomerUser => 'test@localunittest.com',
        OwnerID      => 1,
        UserID       => 1,
    );
    $Self->True(
        $TicketIDOne,
        "Test $Count : TicketCreate() - TicketID $TicketIDOne",
    );
    push @TicketIDs, $TicketIDOne;

    # create article for test ticket one
    my $ArticleIDOne = $TicketObject->ArticleCreate(
        TicketID         => $TicketIDOne,
        ArticleType      => $Test->{ArticleType},
        SenderType       => 'customer',
        Subject          => 'UnitTest article one',
        From             => '"test" <test@localunittest.com>',
        To               => $QueueName,
        Body             => $Test->{ArticleBody},
        Charset          => 'utf-8',
        MimeType         => 'text/html',
        HistoryType      => 'PhoneCallCustomer',
        HistoryComment   => 'Some free text!',
        UserID           => 1,
        UnlockOnAway     => 1,
        AutoResponseType => $Test->{AutoResponseType},
        OrigHeader       => {
            From    => '"test" <test@localunittest.com>',
            To      => $QueueName,
            Subject => 'UnitTest article one',
            Body    => $Test->{OrigHeaderBody},
        },
        Queue => $QueueName,
    );
    $Self->True(
        $ArticleIDOne,
        "Test $Count : ArticleCreate() - ArticleID $ArticleIDOne",
    );

    # check if AutoResponse is sent
    my $Emails = $TestEmailObject->EmailsGet();
    $Self->Is(
        scalar @{$Emails},
        1,
        "Test $Count : Emails fetched from backend - AutoResponse $Test->{AutoResponseType} sent",
    );

    # test auto response <OTRS_CUSTOMER_BODY[n]> tag for HTML article see bug #9837
    if ( $Test->{AutoResponseWithTag} ) {
        $Self->True(
            (
                ${ $Emails->[0]->{Body} }
                    =~ /<a href="http:\/\/www.localhost.com" target="_blank">This is test text with link<\/a>/
            ),
            "Test $Count : <OTRS_CUSTOMER_BODY[n]> tag for AutoResponse - replaced successfully for HTML article",
        );

        $Self->True(
            (
                ${ $Emails->[0]->{Body} }
                    =~ /UnitTest article one/
            ),
            "Test $Count : <OTRS_CUSTOMER_SUBJECT[n]> tag for AutoResponse - replaced successfully for HTML article",
        );
    }

    # clean up test email backend again
    $Success = $TestEmailObject->CleanUp();
    $Self->True(
        $Success,
        "Test $Count : Test backend Email cleanup - success",
    );
    $Self->IsDeeply(
        $TestEmailObject->EmailsGet(),
        [],
        "Test $Count : Test backend Email - empty after cleanup",
    );

    # test if auto-response get activated once it's invalid
    # see bug bug#11481
    # set test AutoResponse on invalid
    $Success = $AutoResponseObject->AutoResponseUpdate(
        ID          => $AutoResponseID,
        Name        => $AutoResponseName,
        ValidID     => 2,
        Subject     => $Test->{Subject},
        Response    => 'UnitTest AutoResponse response',
        ContentType => 'text/plain',
        AddressID   => 1,
        TypeID      => $Test->{AutoResponseTypeID},
        UserID      => 1,
    );
    $Self->True(
        $Success,
        "Test $Count : AutoResponseUpdate() - AutoResponse $Test->{AutoResponseType} - set to invalid",
    );

    # create new test ticket
    my $TicketIDTwo = $TicketObject->TicketCreate(
        Title        => 'UnitTest ticket two',
        QueueID      => $QueueID,
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'open',
        CustomerID   => '12345',
        CustomerUser => 'test@localunittest.com',
        OwnerID      => 1,
        UserID       => 1,
    );
    $Self->True(
        $TicketIDTwo,
        "Test $Count : TicketCreate() - TicketID $TicketIDTwo",
    );
    push @TicketIDs, $TicketIDTwo;

    # create article two for test ticket two
    my $ArticleIDTwo = $TicketObject->ArticleCreate(
        TicketID         => $TicketIDTwo,
        ArticleType      => $Test->{ArticleType},
        SenderType       => 'customer',
        Subject          => 'UnitTest article two',
        From             => '"test" <test@localunittest.com>',
        To               => $QueueName,
        Body             => 'UnitTest body',
        Charset          => 'utf-8',
        MimeType         => 'text/plain',
        HistoryType      => 'PhoneCallCustomer',
        HistoryComment   => 'Some free text!',
        UserID           => 1,
        UnlockOnAway     => 1,
        AutoResponseType => $Test->{AutoResponseType},
        OrigHeader       => {
            From    => '"test" <test@localunittest.com>',
            To      => $QueueName,
            Subject => 'UnitTest article two',
            Body    => 'UnitTest body',

        },
        Queue => $QueueName,
    );
    $Self->True(
        $ArticleIDTwo,
        "Test $Count : ArticleCreate() - ArticleID $ArticleIDTwo",
    );

    # check if AutoResponse is sent while invalid
    $Self->IsDeeply(
        $TestEmailObject->EmailsGet(),
        [],
        "Test $Count : Test backend Email empty - AutoResponse $Test->{AutoResponseType} not sent while invalid",
    );
    $Count++;
}

# clean up test data
# delete test tickets
for my $Ticket (@TicketIDs) {
    $Success = $TicketObject->TicketDelete(
        TicketID => $Ticket,
        UserID   => 1,
    );
    $Self->True(
        $Success,
        "TicketDelete() - TicketID $Ticket",
    );
}

# get DB object
my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

# delete ticket loop-protection
my $SendTo = $DBObject->Quote('test@localunittest.com');
$Success = $DBObject->Do(
    SQL  => 'DELETE FROM ticket_loop_protection WHERE sent_to = ?',
    Bind => [ \$SendTo ],
);
$Self->True(
    $Success,
    "Ticket_loop_protection for $SendTo - deleted",
);

# delete auto-response queue relation
for my $AutoResponseQueue (@QueueIDs) {
    $Success = $DBObject->Do(
        SQL => "DELETE FROM queue_auto_response WHERE queue_id = $AutoResponseQueue",
    );
    $Self->True(
        $Success,
        "AutoResponseQueue for QueueID $AutoResponseQueue relation - deleted",
    );
}

# delete test auto-response
for my $AutoResponse (@AutoResponseIDs) {
    $Success = $DBObject->Do(
        SQL => "DELETE FROM auto_response WHERE id = $AutoResponse",
    );
    $Self->True(
        $Success,
        "AutoResponseID $AutoResponse - deleted",
    );
}

# delete test queue
for my $Queue (@QueueIDs) {
    $Success = $DBObject->Do(
        SQL => "DELETE FROM queue WHERE id = $Queue",
    );
    $Self->True(
        $Success,
        "QueueID $Queue - deleted",
    );
}

# get cache object
my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

# make sure the caches are correct
for my $Cache (
    qw (Ticket Queue AutoResponse QueueAutoResponse)
    )
{
    $CacheObject->CleanUp(
        Type => $Cache,
    );
}

1;
