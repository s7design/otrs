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

use Kernel::System::UnitTest::Helper;

my $HelperObject = Kernel::System::UnitTest::Helper->new();

$HelperObject->BeginWork();

# get needed objects
my $AutoResponseObject  = $Kernel::OM->Get('Kernel::System::AutoResponse');
my $SystemAddressObject = $Kernel::OM->Get('Kernel::System::SystemAddress');
my $QueueObject         = $Kernel::OM->Get('Kernel::System::Queue');

# add test queue
my $QueueRand = 'Some::Queue' . int( rand(1000000) );
my $QueueID   = $QueueObject->QueueAdd(
    Name                => $QueueRand,
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
    "QueueAdd() - $QueueRand, $QueueID",
);

# add system address
my $SystemAddressNameRand0 = 'unittest' . int rand 1000000;
my $SystemAddressID        = $SystemAddressObject->SystemAddressAdd(
    Name     => $SystemAddressNameRand0 . '@example.com',
    Realname => $SystemAddressNameRand0,
    ValidID  => 1,
    QueueID  => $QueueID,
    Comment  => 'Some Comment',
    UserID   => 1,
);
$Self->True(
    $SystemAddressID,
    'SystemAddressAdd()',
);

my %AutoResponseType = $AutoResponseObject->AutoResponseTypeList(
    Valid => 1,    # (optional) default 1
);

for my $TypeID ( sort keys %AutoResponseType ) {

    # add auto response
    my $AutoResponseNameRand = 'unittest' . int rand 1000000;
    my $AutoResponseID       = $AutoResponseObject->AutoResponseAdd(
        Name        => $AutoResponseNameRand,
        Subject     => 'Some Subject',
        Response    => 'Some Response',
        Comment     => 'Some Comment',
        AddressID   => $SystemAddressID,
        TypeID      => $TypeID,
        ContentType => 'text/plain',
        ValidID     => 1,
        UserID      => 1,
    );

    $Self->True(
        $AutoResponseID,
        "AutoResponseAdd() - AutoResponseType: $AutoResponseType{$TypeID}",
    );

    my %AutoResponse = $AutoResponseObject->AutoResponseGet( ID => $AutoResponseID );

    $Self->Is(
        $AutoResponse{Name} || '',
        $AutoResponseNameRand,
        'AutoResponseGet() - Name',
    );
    $Self->Is(
        $AutoResponse{Subject} || '',
        'Some Subject',
        'AutoResponseGet() - Subject',
    );
    $Self->Is(
        $AutoResponse{Response} || '',
        'Some Response',
        'AutoResponseGet() - Response',
    );
    $Self->Is(
        $AutoResponse{Comment} || '',
        'Some Comment',
        'AutoResponseGet() - Comment',
    );
    $Self->Is(
        $AutoResponse{ContentType} || '',
        'text/plain',
        'AutoResponseGet() - ContentType',
    );
    $Self->Is(
        $AutoResponse{AddressID} || '',
        $SystemAddressID,
        'AutoResponseGet() - AddressID',
    );
    $Self->Is(
        $AutoResponse{ValidID} || '',
        1,
        'AutoResponseGet() - ValidID',
    );

    my %AutoResponseList = $AutoResponseObject->AutoResponseList( Valid => 1 );
    my $List = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->True(
        $List,
        'AutoResponseList() - test Auto Response is in the list.',
    );

    my %AutoResponseListByType = $AutoResponseObject->AutoResponseListByType(
        TypeID => $TypeID,
        Valid  => 1,
    );
    $List = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->True(
        $List,
        'AutoResponseListByType() - test Auto Response is in the list.',
    );

    my $AutoResponseQueue = $AutoResponseObject->AutoResponseQueue(
        QueueID         => $QueueID,
        AutoResponseIDs => [$AutoResponseID],
        UserID          => 1,
    );
    $Self->True(
        $AutoResponseQueue,
        'AutoResponseQueue()',
    );

    my $QueueAutoResponseID = $AutoResponseObject->AutoResponseIDForQueueByType(
        TypeID  => $TypeID,
        QueueID => $QueueID,
    );
    $Self->True(
        $QueueAutoResponseID == $AutoResponseID,
        'AutoResponseIDForQueueByType()',
    );

    my %Address = $AutoResponseObject->AutoResponseGetByTypeQueueID(
        QueueID => $QueueID,
        Type    => $AutoResponseType{$TypeID},
    );
    $Self->Is(
        $Address{Address} || '',
        $SystemAddressNameRand0 . '@example.com',
        'AutoResponseGetByTypeQueueID() - Address',
    );
    $Self->Is(
        $Address{Realname} || '',
        $SystemAddressNameRand0,
        'AutoResponseGetByTypeQueueID() - Realname',
    );

    my @GetAutoResponseData = $AutoResponseObject->GetAutoResponseData();
    my @AutoResponseData = grep { $_->{ID} eq $AutoResponseID } @GetAutoResponseData;

    $Self->Is(
        $AutoResponseData[0]->{ID} || '',
        $AutoResponseID,
        'GetAutoResponseData() - ID',
    );
    $Self->Is(
        $AutoResponseData[0]->{Type} || '',
        $AutoResponseType{$TypeID},
        'GetAutoResponseData() - Type',
    );
    $Self->Is(
        $AutoResponseData[0]->{Name} || '',
        $AutoResponseNameRand,
        'GetAutoResponseData() - Name',
    );

    $AutoResponseQueue = $AutoResponseObject->AutoResponseQueue(
        QueueID         => $QueueID,
        AutoResponseIDs => [],
        UserID          => 1,
    );

    my $AutoResponseUpdate = $AutoResponseObject->AutoResponseUpdate(
        ID          => $AutoResponseID,
        Name        => $AutoResponseNameRand . '1',
        Subject     => 'Some Subject1',
        Response    => 'Some Response1',
        Comment     => 'Some Comment1',
        AddressID   => $SystemAddressID,
        TypeID      => $TypeID,
        ContentType => 'text/html',
        ValidID     => 2,
        UserID      => 1,
    );

    $Self->True(
        $AutoResponseUpdate,
        'AutoResponseUpdate()',
    );

    %AutoResponse = $AutoResponseObject->AutoResponseGet( ID => $AutoResponseID );

    $Self->Is(
        $AutoResponse{Name} || '',
        $AutoResponseNameRand . '1',
        'AutoResponseGet() - Name',
    );
    $Self->Is(
        $AutoResponse{Subject} || '',
        'Some Subject1',
        'AutoResponseGet() - Subject',
    );
    $Self->Is(
        $AutoResponse{Response} || '',
        'Some Response1',
        'AutoResponseGet() - Response',
    );
    $Self->Is(
        $AutoResponse{Comment} || '',
        'Some Comment1',
        'AutoResponseGet() - Comment',
    );
    $Self->Is(
        $AutoResponse{ContentType} || '',
        'text/html',
        'AutoResponseGet() - ContentType',
    );
    $Self->Is(
        $AutoResponse{AddressID} || '',
        $SystemAddressID,
        'AutoResponseGet() - AddressID',
    );
    $Self->Is(
        $AutoResponse{ValidID} || '',
        2,
        'AutoResponseGet() - ValidID',
    );

    %AutoResponseList = $AutoResponseObject->AutoResponseList( Valid => 1 );
    $List = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->False(
        $List,
        'AutoResponseList() - test Auto Response is not in the list of valid Auto Responses.',
    );

    %AutoResponseList = $AutoResponseObject->AutoResponseList( Valid => 0 );
    $List = grep { $_ eq $AutoResponseID } keys %AutoResponseList;
    $Self->True(
        $List,
        'AutoResponseList() - test Auto Response is in the list of all Auto Responses.',
    );

}

$HelperObject->Rollback();

1;
