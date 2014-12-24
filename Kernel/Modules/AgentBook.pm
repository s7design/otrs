# --
# Kernel/Modules/AgentBook.pm - addressbook module
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentBook;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    # get params
    for (qw(ToCustomer CcCustomer BccCustomer)) {
        $Param{$_} = $ParamObject->GetParam( Param => $_ );
    }

    # get list of users
    my $Search = $ParamObject->GetParam( Param => 'Search' );
    my %CustomerUserList;
    if ($Search) {
        %CustomerUserList = $CustomerUserObject->CustomerSearch(
            Search => $Search,
        );
    }
    my %List;
    for ( sort keys %CustomerUserList ) {
        my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
            User => $_,
        );
        if ( $CustomerUserData{UserEmail} ) {
            $List{ $CustomerUserData{UserEmail} } = $CustomerUserList{$_};
        }
    }

    # build customer search autocomplete field
    $LayoutObject->Block(
        Name => 'CustomerSearchAutoComplete',
    );

    if (%List) {
        $LayoutObject->Block(
            Name => 'SearchResult',
        );

        my $Count = 1;
        for ( reverse sort { $List{$b} cmp $List{$a} } keys %List ) {
            $LayoutObject->Block(
                Name => 'Row',
                Data => {
                    Name  => $List{$_},
                    Email => $_,
                    Count => $Count,
                },
            );
            $Count++;
        }
    }

    # start with page ...
    my $Output = $LayoutObject->Header( Type => 'Small' );
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentBook',
        Data         => \%Param
    );
    $Output .= $LayoutObject->Footer( Type => 'Small' );

    return $Output;
}

1;
