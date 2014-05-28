# --
# TicketCustomerUserLoginRaw.t - ticket module testscript
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

use strict;
use warnings;
use vars (qw($Self));

use Kernel::Config;
use Kernel::System::CustomerUser;
use Kernel::System::Ticket;
use Kernel::System::UnitTest::Helper;

# create local objects
my $ConfigObject = Kernel::Config->new();

my $UserObject = Kernel::System::User->new(
    %{$Self},
);
my $TicketObject = Kernel::System::Ticket->new(
    %{$Self},
);

# add two users
$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);


my $CustomerUserObject = Kernel::System::CustomerUser->new(
    %{$Self},
    ConfigObject => $ConfigObject,
);

my @CustomerLogins;
my $Rand = int( rand(1000000) );
for my $Key ( 1 .. 2 ) {
    my $UserRand = 'TestCustomerUserLogin + ' . $Key . $Rand;

    my $UserID = $CustomerUserObject->CustomerUserAdd(
        Source         => 'CustomerUser',
        UserFirstname  => 'Firstname Test' . $Key,
        UserLastname   => 'Lastname Test' . $Key,
        UserCustomerID => "CustomerID-$UserRand",
        UserLogin      => $UserRand,
        UserEmail      => $UserRand . '-Email@example.com',
        UserPassword   => 'some_pass',
        ValidID        => 1,
        UserID         => 1,
    );
    push @CustomerLogins, $UserID;

    $Self->True(
        $UserID,
        "CustomerUserAdd() - $UserID",
    );

}

my @TicketIDs;
my %CustomerIDTickets;
for my $CustomerUserLogin (@CustomerLogins) {
    for ( 1 .. 3 ) {

        # create a new ticket
        my $TicketID = $TicketObject->TicketCreate(
            Title        => 'My ticket created by Agent A',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'open',
            CustomerUser => $CustomerUserLogin,
            CustomerID   => "CustomerID-$CustomerUserLogin",
            OwnerID      => 1,
            UserID       => 1,
        );

        $Self->True(
            $TicketID,
            "Ticket created for test - $CustomerUserLogin - $TicketID",
        );
        push @TicketIDs, $TicketID;
        push @{ $CustomerIDTickets{$CustomerUserLogin} }, $TicketID;

    }
}

for my $CustomerUserLogin (@CustomerLogins) {

    my @ReturnedTicketIDs = $TicketObject->TicketSearch(
        Result     => 'ARRAY',
        CustomerUserLoginRaw => $CustomerUserLogin,
        UserID     => 1,
        OrderBy    => ['Up'],
        SortBy     => ['TicketNumber'],
    );
    
    $Self->IsDeeply(
        \@ReturnedTicketIDs,
        $CustomerIDTickets{$CustomerUserLogin},
        "Test TicketSearch for CustomerLoginRaw: \'$CustomerUserLogin\'",
    );
    
}

for my $TicketID (@TicketIDs) {
    my $Success = $TicketObject->TicketDelete(
        TicketID => $TicketID,
        UserID   => 1,
    );
    $Self->True(
        $Success,
        "Removed ticket $TicketID",
    );
}

1;
