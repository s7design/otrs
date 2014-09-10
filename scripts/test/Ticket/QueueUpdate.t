# --
# QueueUpdate.t - ticket module testscript
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
use strict;
use warnings;
use vars (qw($Self));

use utf8;

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');

my $Module = 'StaticDB';

$ConfigObject->Set(
    Key   => 'Ticket::ArchiveSystem',
    Value => 1,
);

$ConfigObject->Set(
    Key   => 'Ticket::IndexModule',
    Value => "Kernel::System::Ticket::IndexAccelerator::$Module",
);

# ticket index accelerator tests
my $RandomString = $HelperObject->GetRandomID();

# test scenarios for Queues
my @Tests = (
    {
        Name => 'QueueFirst',
        Data => {
            QueueName => "QueueFirst$RandomString",
            Comment   => "Some comment for QueueFirst",
        },
    },
    {
        Name => 'QueueSecond',
        Data => {
            QueueName => "QueueSecond$RandomString",
            Comment   => "Some comment for QueueSecond",
        },
    },
);
my $QueueID;
my @Queues;
for my $Test (@Tests) {
    my $QueueID = $QueueObject->QueueAdd(
        Name            => $Test->{Data}->{QueueName},
        ValidID         => 1,
        GroupID         => 1,
        SystemAddressID => 1,
        SalutationID    => 1,
        SignatureID     => 1,
        Comment         => $Test->{Data}->{Comment},
        UserID          => 1,
    );
    push( @Queues, $QueueID );
    $Self->True(
        $QueueID,
        "QueueAdd() - $Test->{Name} - $QueueID",
    );
}

# test scenarios for Tickets
@Tests = (
    {
        Name => 'Ticket 1',
        Data => {
            Title        => 'Some Ticket_Title 1$RandomString ',
            Queue        => "QueueFirst$RandomString",
            CustomerNo   => '123456',
            CustomerUser => 'customer1@example.com',
        },
    },
    {
        Name => 'Ticket 2',
        Data => {
            Title        => 'Some Ticket_Title 2 $RandomString ',
            Queue        => "QueueSecond$RandomString",
            CustomerNo   => '123456',
            CustomerUser => 'customer1@example.com',
        },
    },
    {
        Name => 'Ticket 3',
        Data => {
            Title        => 'Some Ticket_Title 3 $RandomString ',
            Queue        => "QueueSecond$RandomString",
            CustomerNo   => '123456',
            CustomerUser => 'customer1@example.com',
        },
    },
    {
        Name => 'Ticket 4',
        Data => {
            Title        => 'Some Ticket_Title 4 $RandomString ',
            Queue        => "QueueFirst$RandomString",
            CustomerNo   => '654321',
            CustomerUser => 'customer2@example.com',
        },
    },
    {
        Name => 'Ticket 5',
        Data => {
            Title        => 'Some Ticket_Title 5 $RandomString ',
            Queue        => "QueueSecond$RandomString",
            CustomerNo   => '654321',
            CustomerUser => 'customer2@example.com',
        },
    },
    {
        Name => 'Ticket 6',
        Data => {
            Title        => 'Some Ticket_Title 6 $RandomString ',
            Queue        => "QueueFirst$RandomString",
            CustomerNo   => '654321',
            CustomerUser => 'customer2@example.com',
        },
    },
    {
        Name => 'Ticket 7',
        Data => {
            Title        => 'Some Ticket_Title 7 $RandomString ',
            Queue        => "QueueFirst$RandomString",
            CustomerNo   => '654321',
            CustomerUser => 'customer2@example.com',
        },
    },
    {
        Name => 'Ticket 8',
        Data => {
            Title        => 'Some Ticket_Title 8 $RandomString ',
            Queue        => "QueueFirst$RandomString",
            CustomerNo   => '654321',
            CustomerUser => 'customer2@example.com',
        },
    },
    {
        Name => 'Ticket 9',
        Data => {
            Title        => 'Some Ticket_Title 9 $RandomString ',
            Queue        => "QueueFirst$RandomString",
            CustomerNo   => '654321',
            CustomerUser => 'customer2@example.com',
        },
    },
    {
        Name => 'Ticket 10',
        Data => {
            Title        => 'Some Ticket_Title 10 $RandomString ',
            Queue        => "QueueFirst$RandomString",
            CustomerNo   => '654321',
            CustomerUser => 'customer2@example.com',
        },
    },
);
my @TicketIDs;
for my $Test (@Tests) {
    $QueueID = $QueueObject->QueueLookup( Queue => $Test->{Data}->{Queue} );
    my $TicketID = $TicketObject->TicketCreate(
        Title        => $Test->{Data}->{Title},
        QueueID      => $QueueID,
        Lock         => 'unlock',
        Priority     => '3 normal',
        State        => 'new',
        CustomerNo   => $Test->{Data}->{CustomerNo},
        CustomerUser => $Test->{Data}->{CustomerUser},
        OwnerID      => 1,
        UserID       => 1,
    );
    push( @TicketIDs, $TicketID );
    $Self->True(
        $TicketID,
        "$Module $Test->{Name} TicketCreate() - $TicketID ",
    );
}

#loop for each created Queues, updating Queue , and checking ticket index before and after UpdateQueue()
for my $QueueID (@Queues) {
    my %IndexBefore = $TicketObject->TicketAcceleratorIndex(
        UserID        => 1,
        QueueID       => \@Queues,
        ShownQueueIDs => \@Queues,
    );
    my $QueueBefore = $QueueObject->QueueLookup( QueueID => $QueueID );
    my $Updated = $QueueObject->QueueUpdate(
        QueueID         => $QueueID,
        Name            => "New$QueueBefore",
        ValidID         => 1,
        GroupID         => 1,
        SystemAddressID => 1,
        SalutationID    => 1,
        SignatureID     => 1,
        UserID          => 1,
        Comment         => "NEW Comment",
        FollowUpLock    => 1,
        FollowUpID      => 1,
    );
    $Self->True(
        $Updated,
        "Queue:\'$QueueBefore\' is updated",
    );
    my %IndexNow = $TicketObject->TicketAcceleratorIndex(
        UserID        => 1,
        QueueID       => \@Queues,
        ShownQueueIDs => \@Queues,
    );
    my $QueueAfter = $QueueObject->QueueLookup( QueueID => $QueueID );
    $Self->IsNot(
        $QueueAfter,
        $QueueBefore,
        "Compare Queue name - Before:\'$QueueBefore\' => After: \'$QueueAfter\'",
    );
    $Self->Is(
        $IndexBefore{AllTickets} || 0,
        $IndexNow{AllTickets}    || '',
        "$Module TicketAcceleratorIndex() - AllTickets",
    );
    for my $ItemNow ( @{ $IndexNow{Queues} } ) {
        if ( $ItemNow->{Queue} eq $QueueAfter ) {
            for my $ItemBefore ( @{ $IndexBefore{Queues} } ) {
                if ( $ItemBefore->{Queue} eq $QueueBefore ) {
                    $Self->Is(
                        $ItemBefore->{Count} || 0,
                        $ItemNow->{Count}    || '',
                        "$Module TicketAcceleratorIndex() for Queue: $ItemNow->{Queue} - Count",
                    );
                }
            }
        }
    }
}

# delete tickets
for my $TicketID (@TicketIDs) {
    $Self->True(
        $TicketObject->TicketDelete(
            TicketID => $TicketID,
            UserID   => 1,
        ),
        "$Module TicketDelete() - $TicketID",
    );
}

# clean up queue
for my $QueueID (@Queues) {
    my $Success = $DBObject->Do(
        SQL  => 'DELETE FROM queue WHERE id = ?',
        Bind => [ \$QueueID, ]
    );
    $Self->True(
        $Success,
        "Removed queue $QueueID",
    );
}
1;
