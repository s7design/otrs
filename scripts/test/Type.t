# --
# Type.t - Type tests
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::ObjectManager;
my @IDs;

# get needed objects
my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

# add type
my $TypeNameRand0 = 'unittest' . int rand 1000000;

my $TypeID = $TypeObject->TypeAdd(
    Name    => $TypeNameRand0,
    ValidID => 1,
    UserID  => 1,
);

$Self->True(
    $TypeID,
    'TypeAdd()',
);

push( @IDs, $TypeID );

# add type with existing name
my $TypeIDWrong = $TypeObject->TypeAdd(
    Name    => $TypeNameRand0,
    ValidID => 1,
    UserID  => 1,
);

$Self->False(
    $TypeIDWrong,
    'TypeAdd( - try to add type with existing name',
);

# get the type by using the type id
my %Type = $TypeObject->TypeGet( ID => $TypeID );

$Self->Is(
    $Type{Name} || '',
    $TypeNameRand0,
    'TypeGet() - Name (using the type id)',
);
$Self->Is(
    $Type{ValidID} || '',
    1,
    'TypeGet() - ValidID',
);

# get the type by using the type name
%Type = $TypeObject->TypeGet( Name => $TypeNameRand0 );

$Self->Is(
    $Type{Name} || '',
    $TypeNameRand0,
    'TypeGet() - Name (using the type name)',
);

my %TypeList = $TypeObject->TypeList();

my $Hit = 0;
for ( sort keys %TypeList ) {
    if ( $_ eq $TypeID ) {
        $Hit = 1;
    }
}
$Self->True(
    $Hit,
    'TypeList()',
);

my $TypeUpdate = $TypeObject->TypeUpdate(
    ID      => $TypeID,
    Name    => $TypeNameRand0 . '1',
    ValidID => 2,
    UserID  => 1,
);

$Self->True(
    $TypeUpdate,
    'TypeUpdate()',
);

# add another type
my $TypeIDSecond = $TypeObject->TypeAdd(
    Name    => $TypeNameRand0 . '2',
    ValidID => 1,
    UserID  => 1,
);

push( @IDs, $TypeIDSecond );

# update with existing name
my $TypeUpdateWrong = $TypeObject->TypeUpdate(
    ID      => $TypeIDSecond,
    Name    => $TypeNameRand0 . '1',
    ValidID => 1,
    UserID  => 1,
);

$Self->False(
    $TypeUpdateWrong,
    "TypeUpdate() - try to update the type with existing name",
);

%Type = $TypeObject->TypeGet( ID => $TypeID );

$Self->Is(
    $Type{Name} || '',
    $TypeNameRand0 . '1',
    'TypeGet() - Name',
);

$Self->Is(
    $Type{ValidID} || '',
    2,
    'TypeGet() - ValidID',
);

my $TypeLookup = $TypeObject->TypeLookup( TypeID => $TypeID );

$Self->Is(
    $TypeLookup || '',
    $TypeNameRand0 . '1',
    'TypeLookup() - TypeID',
);

my $TypeIDLookup = $TypeObject->TypeLookup( Type => $TypeLookup );

$Self->Is(
    $TypeIDLookup || '',
    $TypeID,
    'TypeLookup() - Type',
);

# perform 2 different TypeLists to check the caching
my %TypeListValid = $TypeObject->TypeList( Valid => 1 );

my %TypeListAll = $TypeObject->TypeList( Valid => 0 );

$Hit = 0;
for ( sort keys %TypeListValid ) {
    if ( $_ eq $TypeID ) {
        $Hit = 1;
    }
}
$Self->False(
    $Hit,
    'TypeList() - only valid types',
);

$Hit = 0;
for ( sort keys %TypeListAll ) {
    if ( $_ eq $TypeID ) {
        $Hit = 1;
    }
}
$Self->True(
    $Hit,
    'TypeList() - all types',
);

# delete created type
for (@IDs) {
    my $TypeDel = $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => "DELETE FROM ticket_type WHERE id = $_",
    );
    $Self->True(
        $_,
        "TypeDelete() - $_",
    );
}

1;
