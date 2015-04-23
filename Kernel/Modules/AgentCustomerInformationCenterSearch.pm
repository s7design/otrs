# --
# Kernel/Modules/AgentCustomerInformationCenterSearch.pm - customer information
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCustomerInformationCenterSearch;
## nofilter(TidyAll::Plugin::OTRS::Perl::DBObject)

use strict;
use warnings;

use Kernel::System::CustomerUser;
use Kernel::System::CustomerCompany;
use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for (qw(ParamObject DBObject LayoutObject LogObject ConfigObject MainObject EncodeObject)) {
        if ( !$Self->{$_} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $_!" );
        }
    }

    $Self->{CustomerUserObject}    = Kernel::System::CustomerUser->new(%Param);
    $Self->{CustomerCompanyObject} = Kernel::System::CustomerCompany->new(%Param);

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $AutoCompleteConfig = $Self->{ConfigObject}->Get('AutoComplete::Agent###CustomerSearch');
    my $LikeEscapeString   = $Self->{DBObject}->GetDatabaseFunction('LikeEscapeString');

    my $MaxResults = $AutoCompleteConfig->{MaxResultsDisplayed} || 20;
    my $IncludeUnknownTicketCustomers = int( $Self->{ParamObject}->GetParam( Param => 'IncludeUnknownTicketCustomers' ) || 0 );
    my $SearchTerm = $Self->{ParamObject}->GetParam( Param => 'Term' ) || '';

    if ( $Self->{Subaction} eq 'SearchCustomerID' ) {

        # build result list
        my $UnknownTicketCustomerList;
       
        if ($IncludeUnknownTicketCustomers) {
            
            # add customers that are not saved in any backend
            $UnknownTicketCustomerList = $Kernel::OM->Get('Kernel::System::Ticket')->SearchUnknownTicketCustomers(
                SearchTerm => $SearchTerm,
            );
        }  

        my %CustomerCompanyList = $Self->{CustomerCompanyObject}->CustomerCompanyList(
            Search => $SearchTerm,
        );
        map {$CustomerCompanyList{$_} = $UnknownTicketCustomerList->{$_}} keys %{$UnknownTicketCustomerList};


        my @CustomerIDs = $Self->{CustomerUserObject}->CustomerIDList(
            SearchTerm => $SearchTerm,
        );

        # add CustomerIDs for which no CustomerCompany are registered
        my %Seen;
        for my $CustomerID (@CustomerIDs) {

            # skip duplicates
            next CUSTOMERID if $Seen{$CustomerID};
            $Seen{$CustomerID} = 1;

            # identifies unknown companies
            if ( !exists $CustomerCompanyList{$CustomerID} ) {
                $CustomerCompanyList{$CustomerID} = $CustomerID;
            }

        }

        my @Result;

        CUSTOMERID:
        for my $CustomerID ( sort keys %CustomerCompanyList ) {
            if ( !( grep { $_->{Value} eq $CustomerID } @Result ) ) {
                push @Result,
                {
                Label => $CustomerCompanyList{$CustomerID},
                Value => $CustomerID
                };
            }        
            last CUSTOMERID if scalar @Result >= $MaxResults;
                
        }

        my $JSON = $Self->{LayoutObject}->JSONEncode(
            Data => \@Result,
        );

        return $Self->{LayoutObject}->Attachment(
            ContentType => 'application/json; charset=' . $Self->{LayoutObject}->{Charset},
            Content     => $JSON || '',
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    elsif ( $Self->{Subaction} eq 'SearchCustomerUser' ) {

        my $UnknownTicketCustomerList;
       
        if ($IncludeUnknownTicketCustomers) {
            
            # add customers that are not saved in any backend
            $UnknownTicketCustomerList = $Kernel::OM->Get('Kernel::System::Ticket')->SearchUnknownTicketCustomers(
                SearchTerm => $SearchTerm,
            );
        }  

        my %CustomerList = $Self->{CustomerUserObject}->CustomerSearch(
            Search => $SearchTerm,
        );
        map {$CustomerList{$_} = $UnknownTicketCustomerList->{$_}} keys %{$UnknownTicketCustomerList};

        my @Result;

        CUSTOMERLOGIN:
        for my $CustomerLogin ( sort keys %CustomerList ) {
            my %CustomerData = $Self->{CustomerUserObject}->CustomerUserDataGet(
                User => $CustomerLogin,
            );
            if ( !( grep { $_->{Value} eq $CustomerData{UserCustomerID} } @Result ) ) {
                push @Result,
                {
                Label => $CustomerList{$CustomerLogin},
                Value => $CustomerData{UserCustomerID}
                };
            }        
            last CUSTOMERLOGIN if scalar @Result >= $MaxResults;
            
        }

        my $JSON = $Self->{LayoutObject}->JSONEncode(
            Data => \@Result,
        );

        return $Self->{LayoutObject}->Attachment(
            ContentType => 'application/json; charset=' . $Self->{LayoutObject}->{Charset},
            Content     => $JSON || '',
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    my $Output .= $Self->{LayoutObject}->Output(
        TemplateFile => 'AgentCustomerInformationCenterSearch',
        Data         => \%Param,
    );
    return $Self->{LayoutObject}->Attachment(
        NoCache     => 1,
        ContentType => 'text/html',
        Charset     => $Self->{LayoutObject}->{UserCharset},
        Content     => $Output || '',
        Type        => 'inline',
    );
}

1;
