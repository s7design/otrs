# --
# Kernel/Modules/AgentCustomerSearch.pm - a module used for the autocomplete feature
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCustomerSearch;
## nofilter(TidyAll::Plugin::OTRS::Perl::DBObject)

use strict;
use warnings;

use Kernel::System::CustomerUser;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for (qw(ParamObject DBObject TicketObject LayoutObject ConfigObject LogObject)) {
        if ( !$Self->{$_} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $_!" );
        }
    }

    # create needed objects
    $Self->{CustomerUserObject} = Kernel::System::CustomerUser->new(%Param);

    # get config
    $Self->{Config} = $Self->{ConfigObject}->Get("Ticket::Frontend::$Self->{Action}");

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $JSON = '';

    # search customers
    if ( !$Self->{Subaction} ) {

        # get needed params
        my $Search = $Self->{ParamObject}->GetParam( Param => 'Term' ) || '';
        my $MaxResults = int( $Self->{ParamObject}->GetParam( Param => 'MaxResults' ) || 20 );
        my $LikeEscapeString = $Self->{DBObject}->GetDatabaseFunction('LikeEscapeString');

        # workaround, all auto completion requests get posted by utf8 anyway
        # convert any to 8bit string if application is not running in utf8
        if ( !$Self->{EncodeObject}->EncodeInternalUsed() ) {
            $Search = $Self->{EncodeObject}->Convert(
                Text => $Search,
                From => 'utf-8',
                To   => $Self->{LayoutObject}->{UserCharset},
            );
        }

        # get customer list
        my %CustomerUserList = $Self->{CustomerUserObject}->CustomerSearch(
            Search => $Search,
        );

        # build data
        my @Data;
        my $MaxResultCount = $MaxResults;
        CUSTOMERUSERID:
        for my $CustomerUserID (
            sort { $CustomerUserList{$a} cmp $CustomerUserList{$b} }
            keys %CustomerUserList
            )
        {

            my $CustomerValue = $CustomerUserList{$CustomerUserID};

            # replace new lines with one space (see bug#11133)
            $CustomerValue =~ s/\n/ /gs;
            $CustomerValue =~ s/\r/ /gs;

            push @Data, {
                CustomerKey   => $CustomerUserID,
                CustomerValue => $CustomerValue,
            };

            $MaxResultCount--;
            last CUSTOMERUSERID if $MaxResultCount <= 0;
        }

        # add customers that are not saved in any backend
        my $QuotedSearch = '%' . $Self->{DBObject}->Quote( $Search, 'Like' ) . '%';
        my $SQL = "SELECT DISTINCT customer_user_id FROM ticket WHERE customer_user_id LIKE ? $LikeEscapeString";
        $Self->{DBObject}->Prepare(
            SQL  => $SQL,
            Bind => [ \$QuotedSearch ],
        );

        # fetch the result
        if ( scalar @Data < $MaxResults ) {
            TICKETCUSTOMERID:
            while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
                if ( $Row[0] && !( grep { $_->{CustomerKey} eq $Row[0] } @Data ) ) {
                    push @Data,
                        {
                        CustomerKey   => $Row[0],
                        CustomerValue => $Row[0]
                        };
                    last TICKETCUSTOMERID if scalar @Data >= $MaxResults;
                }
            }
        }

        # build JSON output
        $JSON = $Self->{LayoutObject}->JSONEncode(
            Data => \@Data,
        );
    }

    # get customer info
    elsif ( $Self->{Subaction} eq 'CustomerInfo' ) {

        # get params
        my $CustomerUserID = $Self->{ParamObject}->GetParam( Param => 'CustomerUserID' ) || '';

        my $CustomerID              = '';
        my $CustomerTableHTMLString = '';

        # get customer data
        my %CustomerData = $Self->{CustomerUserObject}->CustomerUserDataGet(
            User => $CustomerUserID,
        );

        # get customer id
        if ( $CustomerData{UserCustomerID} ) {
            $CustomerID = $CustomerData{UserCustomerID};
        }

        # build html for customer info table
        if ( $Self->{ConfigObject}->Get('Ticket::Frontend::CustomerInfoCompose') ) {

            $CustomerTableHTMLString = $Self->{LayoutObject}->AgentCustomerViewTable(
                Data => {%CustomerData},
                Max  => $Self->{ConfigObject}->Get('Ticket::Frontend::CustomerInfoComposeMaxSize'),
            );
        }

        # build JSON output
        $JSON = $Self->{LayoutObject}->JSONEncode(
            Data => {
                CustomerID              => $CustomerID,
                CustomerTableHTMLString => $CustomerTableHTMLString,
            },
        );
    }

    # get customer tickets
    elsif ( $Self->{Subaction} eq 'CustomerTickets' ) {

        # get params
        my $CustomerUserID = $Self->{ParamObject}->GetParam( Param => 'CustomerUserID' ) || '';
        my $CustomerID     = $Self->{ParamObject}->GetParam( Param => 'CustomerID' )     || '';

        # get secondary customer ids
        my @CustomerIDs;
        if ($CustomerUserID) {
            @CustomerIDs = $Self->{CustomerUserObject}->CustomerIDs(
                User => $CustomerUserID,
            );
        }

        # add own customer id
        if ($CustomerID) {
            push @CustomerIDs, $CustomerID;
        }

        my $View    = $Self->{ParamObject}->GetParam( Param => 'View' )    || '';
        my $SortBy  = $Self->{ParamObject}->GetParam( Param => 'SortBy' )  || 'Age';
        my $OrderBy = $Self->{ParamObject}->GetParam( Param => 'OrderBy' ) || 'Down';

        my @ViewableTickets;
        if (@CustomerIDs) {
            @ViewableTickets = $Self->{TicketObject}->TicketSearch(
                Result        => 'ARRAY',
                Limit         => 250,
                SortBy        => [$SortBy],
                OrderBy       => [$OrderBy],
                CustomerIDRaw => \@CustomerIDs,
                UserID        => $Self->{UserID},
                Permission    => 'ro',
            );
        }

        my $LinkSort = 'Subaction=' . $Self->{Subaction}
            . ';View=' . $Self->{LayoutObject}->Ascii2Html( Text => $View )
            . ';CustomerUserID=' . $Self->{LayoutObject}->Ascii2Html( Text => $CustomerUserID )
            . ';CustomerID=' . $Self->{LayoutObject}->Ascii2Html( Text => $CustomerID )
            . '&';
        my $LinkPage = 'Subaction=' . $Self->{Subaction}
            . ';View=' . $Self->{LayoutObject}->Ascii2Html( Text => $View )
            . ';SortBy=' . $Self->{LayoutObject}->Ascii2Html( Text => $SortBy )
            . ';OrderBy=' . $Self->{LayoutObject}->Ascii2Html( Text => $OrderBy )
            . ';CustomerUserID=' . $Self->{LayoutObject}->Ascii2Html( Text => $CustomerUserID )
            . ';CustomerID=' . $Self->{LayoutObject}->Ascii2Html( Text => $CustomerID )
            . '&';
        my $LinkFilter = 'Subaction=' . $Self->{Subaction}
            . ';CustomerUserID=' . $Self->{LayoutObject}->Ascii2Html( Text => $CustomerUserID )
            . ';CustomerID=' . $Self->{LayoutObject}->Ascii2Html( Text => $CustomerID )
            . '&';

        my $CustomerTicketsHTMLString = '';
        if (@ViewableTickets) {
            $CustomerTicketsHTMLString .= $Self->{LayoutObject}->TicketListShow(
                TicketIDs  => \@ViewableTickets,
                Total      => scalar @ViewableTickets,
                Env        => $Self,
                View       => $View,
                TitleName  => 'Customer History',
                LinkPage   => $LinkPage,
                LinkSort   => $LinkSort,
                LinkFilter => $LinkFilter,
                Output     => 'raw',

                OrderBy => $OrderBy,
                SortBy  => $SortBy,
                AJAX    => 1,
            );
        }

        # build JSON output
        $JSON = $Self->{LayoutObject}->JSONEncode(
            Data => {
                CustomerTicketsHTMLString => $CustomerTicketsHTMLString,
            },
        );
    }

    # send JSON response
    return $Self->{LayoutObject}->Attachment(
        ContentType => 'application/json; charset=' . $Self->{LayoutObject}->{Charset},
        Content     => $JSON || '',
        Type        => 'inline',
        NoCache     => 1,
    );

}

1;
