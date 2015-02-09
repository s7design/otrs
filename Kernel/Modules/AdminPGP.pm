# --
# Kernel/Modules/AdminPGP.pm - to add/update/delete pgp keys
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminPGP;

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

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # ------------------------------------------------------------ #
    # check if feature is active
    # ------------------------------------------------------------ #
    if ( !$ConfigObject->Get('PGP') ) {

        my $Output .= $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        $LayoutObject->Block( Name => 'Overview' );
        $LayoutObject->Block( Name => 'Disabled' );

        $Output .= $LayoutObject->Output( TemplateFile => 'AdminPGP' );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    $Param{Search} = $ParamObject->GetParam( Param => 'Search' );
    if ( !defined( $Param{Search} ) ) {
        $Param{Search} = $Self->{PGPSearch} || '';
    }
    if ( $Self->{Subaction} eq '' ) {
        $Param{Search} = '';
    }

    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    $SessionObject->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'PGPSearch',
        Value     => $Param{Search},
    );

    my $CryptObject = Kernel::System::Crypt->new(
        CryptType => 'PGP',
    );

    # ------------------------------------------------------------ #
    # delete key
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Delete' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        $LayoutObject->Block( Name => 'Overview' );
        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionSearch' );
        $LayoutObject->Block( Name => 'ActionAdd' );
        $LayoutObject->Block( Name => 'Hint' );
        $LayoutObject->Block( Name => 'OverviewResult' );

        my $Key  = $ParamObject->GetParam( Param => 'Key' )  || '';
        my $Type = $ParamObject->GetParam( Param => 'Type' ) || '';
        if ( !$Key ) {
            return $LayoutObject->ErrorScreen(
                Message => 'Need param Key to delete!',
            );
        }
        my $Success = '';
        if ( $Type eq 'sec' ) {
            $Success = $CryptObject->SecretKeyDelete( Key => $Key );
        }
        else {
            $Success = $CryptObject->PublicKeyDelete( Key => $Key );
        }
        my @List = $CryptObject->KeySearch( Search => $Param{Search} );
        if (@List) {
            for my $Key (@List) {
                $LayoutObject->Block(
                    Name => 'Row',
                    Data => { %{$Key} },
                );
            }
        }
        else {
            $LayoutObject->Block(
                Name => 'NoDataFoundMsg',
                Data => {},
            );
        }
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        my $Message = '';
        if ($Success) {
            $Message = "Key $Key deleted!";
        }
        else {
            $Message = $Kernel::OM->Get('Kernel::System::Log')->GetLogEntry(
                Type => 'Error',
                What => 'Message',
            );
        }
        $Output .= $LayoutObject->Notify( Info => $Message );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPGP',
            Data         => \%Param
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add key (form)
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        $LayoutObject->Block( Name => 'Overview' );
        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionOverview' );
        $LayoutObject->Block( Name => 'AddKey' );

        $Output .= $LayoutObject->Output( TemplateFile => 'AdminPGP' );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add key
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddKey' ) {

        my %Errors;

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        $SessionObject->UpdateSessionID(
            SessionID => $Self->{SessionID},
            Key       => 'PGPSearch',
            Value     => '',
        );
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'FileUpload',
        );
        if ( !%UploadStuff ) {
            $Errors{FileUploadInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            # add pgp key
            my $KeyAdd = $CryptObject->KeyAdd( Key => $UploadStuff{Content} );

            if ($KeyAdd) {
                $LayoutObject->Block( Name => 'Overview' );
                $LayoutObject->Block( Name => 'ActionList' );
                $LayoutObject->Block( Name => 'ActionSearch' );
                $LayoutObject->Block( Name => 'ActionAdd' );
                $LayoutObject->Block( Name => 'OverviewResult' );

                my @List = $CryptObject->KeySearch( Search => '' );
                if (@List) {
                    for my $Key (@List) {
                        $LayoutObject->Block(
                            Name => 'Row',
                            Data => { %{$Key} },
                        );
                    }
                }
                else {
                    $LayoutObject->Block(
                        Name => 'NoDataFoundMsg',
                        Data => {},
                    );
                }

                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => $KeyAdd );

                $Output .= $LayoutObject->Output( TemplateFile => 'AdminPGP' );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $LayoutObject->Block( Name => 'Overview' );
        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionOverview' );
        $LayoutObject->Block(
            Name => 'AddKey',
            Data => \%Errors,
        );
        $Output .= $LayoutObject->Output( TemplateFile => 'AdminPGP' );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # download key
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Download' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Key  = $ParamObject->GetParam( Param => 'Key' )  || '';
        my $Type = $ParamObject->GetParam( Param => 'Type' ) || '';
        if ( !$Key ) {
            return $LayoutObject->ErrorScreen(
                Message => 'Need param Key to download!',
            );
        }
        my $KeyString = '';
        if ( $Type eq 'sec' ) {
            $KeyString = $CryptObject->SecretKeyGet( Key => $Key );
        }
        else {
            $KeyString = $CryptObject->PublicKeyGet( Key => $Key );
        }
        return $LayoutObject->Attachment(
            ContentType => 'text/plain',
            Content     => $KeyString,
            Filename    => "$Key.asc",
            Type        => 'attachment',
        );
    }

    # ------------------------------------------------------------ #
    # download fingerprint
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'DownloadFingerprint' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Key  = $ParamObject->GetParam( Param => 'Key' )  || '';
        my $Type = $ParamObject->GetParam( Param => 'Type' ) || '';
        if ( !$Key ) {
            return $LayoutObject->ErrorScreen(
                Message => 'Need param Key to download!',
            );
        }
        my $Download = '';
        if ( $Type eq 'sec' ) {
            my @Result = $CryptObject->PrivateKeySearch( Search => $Key );
            if ( $Result[0] ) {
                $Download = $Result[0]->{Fingerprint};
            }
        }
        else {
            my @Result = $CryptObject->PublicKeySearch( Search => $Key );
            if ( $Result[0] ) {
                $Download = $Result[0]->{Fingerprint};
            }
        }
        return $LayoutObject->Attachment(
            ContentType => 'text/plain',
            Content     => $Download,
            Filename    => "$Key.txt",
            Type        => 'attachment',
        );
    }

    # ------------------------------------------------------------ #
    # search key
    # ------------------------------------------------------------ #
    else {

        my $Output .= $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        if ( !$CryptObject && $ConfigObject->Get('PGP') ) {
            $Output .= $LayoutObject->Notify(
                Priority => 'Error',
                Data     => $LayoutObject->{LanguageObject}->Translate( "Cannot create %s!", "CryptObject" ),
                Link =>
                    $LayoutObject->{Baselink}
                    . 'Action=AdminSysConfig;Subaction=Edit;SysConfigGroup=Framework;SysConfigSubGroup=Crypt::PGP',
            );
        }

        $LayoutObject->Block( Name => 'Overview' );
        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionSearch' );
        $LayoutObject->Block( Name => 'ActionAdd' );
        $LayoutObject->Block( Name => 'Hint' );
        $LayoutObject->Block( Name => 'OverviewResult' );

        my @List = ();
        if ($CryptObject) {
            @List = $CryptObject->KeySearch( Search => $Param{Search} );
        }
        if (@List) {
            for my $Key (@List) {
                $LayoutObject->Block(
                    Name => 'Row',
                    Data => { %{$Key} },
                );
            }
        }
        else {
            $LayoutObject->Block(
                Name => 'NoDataFoundMsg',
                Data => {},
            );
        }

        if ( $CryptObject && $CryptObject->Check() ) {
            $Output .= $LayoutObject->Notify(
                Priority => 'Error',
                Data     => $LayoutObject->{LanguageObject}->Translate( $CryptObject->Check() ),
            );
        }
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPGP',
            Data         => \%Param
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

1;
