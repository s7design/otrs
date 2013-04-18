# --
# Kernel/System/CustomerCompany.pm - All customer company related function should be here eventually
# Copyright (C) 2001-2013 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::CustomerCompany;

use strict;
use warnings;

use Kernel::System::Valid;
use Kernel::System::Cache;

use vars qw(@ISA);

=head1 NAME

Kernel::System::CustomerCompany - customer company lib

=head1 SYNOPSIS

All Customer Company functions. E.g. to add and update customer companies.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::Time;
    use Kernel::System::DB;
    use Kernel::System::CustomerCompany;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $TimeObject = Kernel::System::Time->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $CustomerCompanyObject = Kernel::System::CustomerCompany->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        TimeObject   => $TimeObject,
        EncodeObject => $EncodeObject,
        MainObject   => $MainObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for (qw(DBObject ConfigObject LogObject MainObject EncodeObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    $Self->{ValidObject} = Kernel::System::Valid->new( %{$Self} );

    # load customer company backend modules
    for my $Count ( '', 1 .. 10 ) {

        # next if backend is not used
        next if !$Self->{ConfigObject}->Get("CustomerCompany$Count");

        my $GenericModule = $Self->{ConfigObject}->Get("CustomerCompany$Count")->{Module};
        if ( !$Self->{MainObject}->Require($GenericModule) ) {
            $Self->{MainObject}->Die("Can't load backend module $GenericModule! $@");
        }
        $Self->{"CustomerCompany$Count"} = $GenericModule->new(
            Count => $Count,
            %Param,
            CustomerCompanyMap   => $Self->{ConfigObject}->Get("CustomerCompany$Count"),
        );
    }

    return $Self;
}

=item CustomerCompanyAdd()

add a new customer company

    my $ID = $CustomerCompanyObject->CustomerCompanyAdd(
        CustomerID              => 'example.com',
        CustomerCompanyName     => 'New Customer Company Inc.',
        CustomerCompanyStreet   => '5201 Blue Lagoon Drive',
        CustomerCompanyZIP      => '33126',
        CustomerCompanyCity     => 'Miami',
        CustomerCompanyCountry  => 'USA',
        CustomerCompanyURL      => 'http://www.example.org',
        CustomerCompanyComment  => 'some comment',
        ValidID                 => 1,
        UserID                  => 123,
    );

NOTE: Actual fields accepted by this API call may differ based on
CustomerCompany mapping in your system configuration.

=cut

sub CustomerCompanyAdd {
    my ( $Self, %Param ) = @_;

    # check data source
    if ( !$Param{Source} ) {
        $Param{Source} = 'CustomerCompany';
    }

    # check needed stuff
    for (qw(CustomerID UserID)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    return $Self->{ $Param{Source} }->CustomerCompanyAdd(%Param);

}

=item CustomerCompanyGet()

get customer company attributes

    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => 123,
    );

Returns:

    %CustomerCompany = (
        'CustomerCompanyName'    => 'Customer Company Inc.',
        'CustomerID'             => 'example.com',
        'CustomerCompanyStreet'  => '5201 Blue Lagoon Drive',
        'CustomerCompanyZIP'     => '33126',
        'CustomerCompanyCity'    => 'Miami',
        'CustomerCompanyCountry' => 'United States',
        'CustomerCompanyURL'     => 'http://example.com',
        'CustomerCompanyComment' => 'Some Comments',
        'ValidID'                => '1',
        'CreateTime'             => '2010-10-04 16:35:49',
        'ChangeTime'             => '2010-10-04 16:36:12',
    );

NOTE: Actual fields returned by this API call may differ based on
CustomerCompany mapping in your system configuration.

=cut

sub CustomerCompanyGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{CustomerID} ) {
        $Self->{LogObject}->Log( Priority => 'error', Message => "Need CustomerID!" );
        return;
    }

    for my $Count ( '', 1 .. 10 ) {

        # next if backend is not used
        next if !$Self->{"CustomerCompany$Count"};

        # next if no company got found
        my %Company = $Self->{"CustomerCompany$Count"}->CustomerCompanyGet( %Param, );
        next if !%Company;

        # return company data
        return (
            %Company,
            Source        => "CustomerCompany$Count",
            Config        => $Self->{ConfigObject}->Get("CustomerCompany$Count"),
        );
    }
    return;
}

=item CustomerCompanyUpdate()

update customer company attributes

    $CustomerCompanyObject->CustomerCompanyUpdate(
        CustomerCompanyID       => 'oldexample.com', #required if CustomerCompanyID-update
        CustomerID              => 'example.com',
        CustomerCompanyName     => 'New Customer Company Inc.',
        CustomerCompanyStreet   => '5201 Blue Lagoon Drive',
        CustomerCompanyZIP      => '33126',
        CustomerCompanyLocation => 'Miami',
        CustomerCompanyCountry  => 'USA',
        CustomerCompanyURL      => 'http://example.com',
        CustomerCompanyComment  => 'some comment',
        ValidID                 => 1,
        UserID                  => 123,
    );

=cut

sub CustomerCompanyUpdate {
    my ( $Self, %Param ) = @_;

    $Param{CustomerCompanyID} ||= $Param{CustomerID};

    # check needed stuff
    if ( !$Param{CustomerCompanyID} ) {
        $Self->{LogObject}->Log( Priority => 'error', Message => "Need CustomerCompanyID or CustomerID!" );
        return;
    }

    # check if company exists
    my %Company = $Self->CustomerCompanyGet( CustomerID => $Param{CustomerCompanyID} );
    if ( !%Company ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "No such company '$Param{CustomerCompanyID}'!",
        );
        return;
    }
    return $Self->{ $Company{Source} }->CustomerCompanyUpdate(%Param);
}

=item CustomerCompanyList()

get list of customer companies.

    my %List = $CustomerCompanyObject->CustomerCompanyList();

    my %List = $CustomerCompanyObject->CustomerCompanyList(
        Valid => 0,
    );

    my %List = $CustomerCompanyObject->CustomerCompanyList(
        Search => 'somecompany',
    );

Returns:

%List = {
          'example.com' => 'example.com Customer Company Inc.        ',
          'acme.com'    => 'acme.com Acme, Inc.        '
        };

=cut

sub CustomerCompanyList {
    my ( $Self, %Param ) = @_;

    my %Data;
    for my $Count ( '', 1 .. 10 ) {

        # next if backend is not used
        next if !$Self->{"CustomerCompany$Count"};

        # get comppany list result of backend and merge it
        my %SubData = $Self->{"CustomerCompany$Count"}->CustomerCompanyList(%Param);
        %Data = ( %Data, %SubData );
    }
    return %Data;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
