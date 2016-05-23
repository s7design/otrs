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

# get needed objects
my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# get needed variables
my @QueueNames;
my @QueueIDs;

# create test queues
for ( 0 .. 1 ) {
    my $QueueName = $Helper->GetRandomID();
    my $QueueID   = $QueueObject->QueueAdd(
        Name                => $QueueName,
        ValidID             => 1,
        GroupID             => 1,
        FirstResponseTime   => 30,
        FirstResponseNotify => 70,
        UpdateTime          => 240,
        UpdateNotify        => 80,
        SolutionTime        => 2440,
        SolutionNotify      => 90,
        SystemAddressID     => 1,
        SalutationID        => 1,
        SignatureID         => 1,
        UserID              => 1,
        Comment             => 'Some Comment',
    );
    $Self->True(
        $QueueID,
        "QueueID $QueueID is created",
    );
    push @QueueNames, $QueueName;
    push @QueueIDs,   $QueueID;
}

# add system address
my $SystemAddressEmail    = $Helper->GetRandomID() . '@example.com';
my $SystemAddressRealname = "OTRS-Team";

my %SystemAddressData = (
    Name     => $SystemAddressEmail,
    Realname => $SystemAddressRealname,
    Comment  => 'some comment',
    QueueID  => $QueueIDs[0],
    ValidID  => 1,
);

my $SystemAddressID = $SystemAddressObject->SystemAddressAdd(
    %SystemAddressData,
    UserID => 1,
);
$Self->True(
    $SystemAddressID,
    "SystemAddressID $SystemAddressID is created",
);

my %SystemAddress = $SystemAddressObject->SystemAddressGet(
    ID => $SystemAddressID
);

for my $Key ( sort keys %SystemAddressData ) {
    $Self->Is(
        $SystemAddress{$Key},
        $SystemAddressData{$Key},
        'SystemAddressGet() - $Key',
    );
}

# caching
%SystemAddress = $SystemAddressObject->SystemAddressGet(
    ID => $SystemAddressID
);

for my $Key ( sort keys %SystemAddressData ) {
    $Self->Is(
        $SystemAddress{$Key},
        $SystemAddressData{$Key},
        'SystemAddressGet() - $Key',
    );
}

my %SystemAddressList = $SystemAddressObject->SystemAddressList( Valid => 0 );
$Self->True(
    exists $SystemAddressList{$SystemAddressID} && $SystemAddressList{$SystemAddressID} eq $SystemAddressEmail,
    "SystemAddressList() contains the SystemAddress $SystemAddressID",
);

# caching
%SystemAddressList = $SystemAddressObject->SystemAddressList( Valid => 1 );
$Self->True(
    exists $SystemAddressList{$SystemAddressID} && $SystemAddressList{$SystemAddressID} eq $SystemAddressEmail,
    "SystemAddressList() contains the SystemAddress $SystemAddressID",
);

my @Tests = (
    {
        Address => uc($SystemAddressEmail),
        QueueID => $QueueIDs[0],
    },
    {
        Address => lc($SystemAddressEmail),
        QueueID => $QueueIDs[0],
    },
    {
        Address => $SystemAddressEmail,
        QueueID => $QueueIDs[0],
    },
    {
        Address => '2' . $SystemAddressEmail,
        QueueID => undef,
    },
    {
        Address => ', ' . $SystemAddressEmail,
        QueueID => undef,
    },
    {
        Address => ')' . $SystemAddressEmail,
        QueueID => undef,
    },
);
for my $Test (@Tests) {
    my $QueueID = $SystemAddressObject->SystemAddressQueueID( Address => $Test->{Address} );
    $Self->Is(
        $QueueID,
        $Test->{QueueID},
        "SystemAddressQueueID() - $Test->{Address}",
    );

    # cached
    $QueueID = $SystemAddressObject->SystemAddressQueueID( Address => $Test->{Address} );
    $Self->Is(
        $QueueID,
        $Test->{QueueID},
        "SystemAddressQueueID() - $Test->{Address}",
    );
}

# update queue with SystemAddressID
my $Success = $QueueObject->QueueUpdate(
    QueueID         => $QueueIDs[0],
    Name            => $QueueNames[0],
    ValidID         => 1,
    GroupID         => 1,
    SystemAddressID => $SystemAddressID,
    SalutationID    => 1,
    SignatureID     => 1,
    UserID          => 1,
    FollowUpID      => 1,
);
$Self->True(
    $Success,
    "QueueID $QueueIDs[0] is updated - connected with SystemAddressID $SystemAddressID",
);

# update system address
my $SystemAddressUpdate = $SystemAddressObject->SystemAddressUpdate(
    ID       => $SystemAddressID,
    Name     => $SystemAddressEmail,
    ValidID  => 2,
    Realname => $SystemAddressRealname,
    QueueID  => $QueueIDs[0],
    UserID   => 1,
);
$Self->False(
    $SystemAddressUpdate,
    "SystemAddressUpdate can't set address $SystemAddressEmail to invalid - queueID $QueueIDs[0] is connected with it",
);

# update queue back
$Success = $QueueObject->QueueUpdate(
    QueueID         => $QueueIDs[0],
    Name            => $QueueNames[0],
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
    "QueueID $QueueIDs[0] is updated - connected with SystemAddressID 1",
);

my %SystemAddressDataUpdate = (
    Name     => '2' . $SystemAddressEmail,
    Realname => '2' . $SystemAddressRealname,
    Comment  => 'some comment 1',
    QueueID  => $QueueIDs[1],
    ValidID  => 2,
);

$SystemAddressUpdate = $SystemAddressObject->SystemAddressUpdate(
    %SystemAddressDataUpdate,
    ID     => $SystemAddressID,
    UserID => 1,
);
$Self->True(
    $SystemAddressUpdate,
    'SystemAddressUpdate()',
);

%SystemAddress = $SystemAddressObject->SystemAddressGet( ID => $SystemAddressID );

for my $Key ( sort keys %SystemAddressDataUpdate ) {
    $Self->Is(
        $SystemAddress{$Key},
        $SystemAddressDataUpdate{$Key},
        'SystemAddressGet() - $Key',
    );
}

# add test valid system address
my $SystemAddressID1 = $SystemAddressObject->SystemAddressAdd(
    Name     => $SystemAddressEmail . 'first',
    Realname => $SystemAddressRealname . 'first',
    Comment  => 'some comment',
    QueueID  => $QueueIDs[0],
    ValidID  => 1,
    UserID   => 1,
);

# test SystemAddressQueueList() method - get all addresses
my %SystemQueues = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressQueueList( Valid => 0 );

$Self->True(
    exists $SystemQueues{ $QueueIDs[1] } && $SystemQueues{ $QueueIDs[1] } == $SystemAddressID,
    "SystemAddressQueueList() contains the QueueID2",
);
$Self->True(
    exists $SystemQueues{ $QueueIDs[0] } && $SystemQueues{ $QueueIDs[0] } == $SystemAddressID1,
    "SystemAddressQueueList() contains the QueueID1",
);

# test SystemAddressQueueList() method -  get only valid system addresses
%SystemQueues = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressQueueList( Valid => 1 );

$Self->False(
    exists $SystemQueues{ $QueueIDs[1] },
    "SystemAddressQueueList() does not contain the invalid QueueID2",
);
$Self->True(
    exists $SystemQueues{ $QueueIDs[0] } && $SystemQueues{ $QueueIDs[0] } == $SystemAddressID1,
    "SystemAddressQueueList() contains the valid QueueID1",
);

# cleanup is done by RestoreDatabase

1;
