# --
# Kernel/System/Queue/Event/QueueUpdate.pm - update statement on TicketIndex to rename the queue name there if needed and if StaticDB is actually used
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::Queue::Event::QueueUpdate;
use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw( Data Event Config UserID )) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')
                ->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Module = $ConfigObject->Get('Ticket::IndexModule');

    #check if ticket index accelerator module is StaticDB
    if ( $Module eq 'Kernel::System::Ticket::IndexAccelerator::StaticDB' ) {

        # only update if Queue has really changed
        return 1 if $Param{Data}->{Queue}->{Name} eq $Param{Data}->{OldQueue}->{Name};

        # update ticket_index
        if (
            !$TicketObject->TicketAcceleratorUpdateOnQueueUpdate(
                NewQueueName => $Param{Data}->{Queue}->{Name},
                OldQueueName => $Param{Data}->{OldQueue}->{Name},
            )
            )
        {

            $Kernel::OM->Get('Kernel::System::Log')
                ->Log(
                Priority => 'error',
                Message  => "Error during update queue in ticket_index! "
                );
        }
    }
    return 1;
}
1;
