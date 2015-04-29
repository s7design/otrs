# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Preferences::Skin;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Web::Request',
    'Kernel::Config',
    'Kernel::System::User',
    'Kernel::System::AuthSession',
    'Kernel::Output::HTML::Layout',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    for my $Needed (qw(UserID ConfigItem)) {
        $Self->{$Needed} = $Param{$Needed} || die "Got no $Needed!";
    }

    return $Self;
}

sub Param {
    my ( $Self, %Param ) = @_;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $PossibleSkins = $ConfigObject->Get('Loader::Agent::Skin') || {};
    my $Home = $ConfigObject->Get('Home');
    my %ActiveSkins;

    # prepare the list of active skins
    for my $PossibleSkin ( values %{$PossibleSkins} ) {
        if (
            $Kernel::OM->Get('Kernel::Output::HTML::Layout')->SkinValidate(
                Skin     => $PossibleSkin->{InternalName},
                SkinType => 'Agent'
            )
            )
        {
            $ActiveSkins{ $PossibleSkin->{InternalName} } = $PossibleSkin->{VisibleName};
        }
    }

    my @Params;
    push(
        @Params,
        {
            %Param,
            Name       => $Self->{ConfigItem}->{PrefKey},
            Data       => \%ActiveSkins,
            HTMLQuote  => 0,
            SelectedID => $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'UserSkin' )
                || $Param{UserData}->{UserSkin}
                || $ConfigObject->Get('Loader::Agent::DefaultSelectedSkin'),
            Block => 'Option',
            Max   => 100,
        },
    );
    return @Params;
}

sub Run {
    my ( $Self, %Param ) = @_;

    for my $Key ( sort keys %{ $Param{GetParam} } ) {
        my @Array = @{ $Param{GetParam}->{$Key} };
        for my $Value (@Array) {

            # pref update db
            if ( !$Kernel::OM->Get('Kernel::Config')->Get('DemoSystem') ) {
                $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
                    UserID => $Param{UserData}->{UserID},
                    Key    => $Key,
                    Value  => $Value,
                );
            }

            # update SessionID
            if ( $Param{UserData}->{UserID} eq $Self->{UserID} ) {
                $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
                    SessionID => $Self->{SessionID},
                    Key       => $Key,
                    Value     => $Value,
                );
            }
        }
    }
    $Self->{Message} = 'Preferences updated successfully!';
    return 1;
}

sub Error {
    my ( $Self, %Param ) = @_;

    return $Self->{Error} || '';
}

sub Message {
    my ( $Self, %Param ) = @_;

    return $Self->{Message} || '';
}

1;
