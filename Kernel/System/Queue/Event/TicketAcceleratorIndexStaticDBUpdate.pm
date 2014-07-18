# --
# Kernel/System/Queue/Event/TicketAcceleratorIndexStaticDBUpdate.pm - update statement on TicketIndex to rename the queue name there if needed and if StaticDB is actually used
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Queue::Event::TicketAcceleratorIndexStaticDBUpdate;

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';
use Kernel::System::ObjectManager;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for (
        qw( ConfigObject EncodeObject LogObject MainObject DBObject)
        )
    {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # common objects
    local $Kernel::OM = Kernel::System::ObjectManager->new(
        LogObject => {
            LogPrefix => 'OTRS-QueueUpdate',
        },
    );

    my %CommonObject = $Kernel::OM->ObjectHash(
        Objects =>
            [qw(ConfigObject EncodeObject LogObject MainObject TimeObject DBObject TicketObject)],
    );

    my $Module = $Self->{ConfigObject}->Get('Ticket::IndexModule');
    
    #check if ticket index accelerator module is StaticDB
    if ( $Module eq 'Kernel::System::Ticket::IndexAccelerator::StaticDB' ) {

        # only update if Queue has really changed   
        return 1 if $Param{Data}->{Queue}->{Name} eq $Param{Data}->{OldQueue}->{Name};

        # rebuild
        if ( !$CommonObject{TicketObject}->TicketAcceleratorRebuild() ) {
            $CommonObject{LogObject}->Log( Priority => 'error' ,Message =>"TicketAcceleratorRebuild error during update of queue! ");
        }
    }

    return 1;
}

1;
