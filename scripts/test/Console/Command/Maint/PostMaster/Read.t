# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# Get helper object.
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Get needed objects.
my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Maint::PostMaster::Read');
my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');

my $RandomNumber = $Helper->GetRandomNumber();

# use Test email backend
$ConfigObject->Set(
    Key   => 'SendmailModule',
    Value => 'Kernel::System::Email::Test',
);
$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => '0',
);

# Create customer company.
my $CustomerCompany   = 'Company' . $RandomNumber;
my $CustomerCompanyID = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyAdd(
    CustomerID             => $CustomerCompany,
    CustomerCompanyName    => $CustomerCompany,
    CustomerCompanyStreet  => $CustomerCompany,
    CustomerCompanyZIP     => $CustomerCompany,
    CustomerCompanyCity    => $CustomerCompany,
    CustomerCompanyCountry => 'Germany',
    CustomerCompanyURL     => 'http://www.otrs.com',
    CustomerCompanyComment => $CustomerCompany,
    ValidID                => 1,
    UserID                 => 1,
);
$Self->True(
    $CustomerCompany,
    "CustomerCompanyID $CustomerCompanyID is created",
);

# Create customer user.
my $CustomerUser             = 'User' . $RandomNumber;
my $CustomerUserEmailAddress = $CustomerUser . '@example.com';
my $CustomerUserID           = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserAdd(
    Source         => 'CustomerUser',
    UserFirstname  => $CustomerUser,
    UserLastname   => $CustomerUser,
    UserCustomerID => $CustomerCompanyID,
    UserLogin      => $CustomerUser,
    UserEmail      => $CustomerUserEmailAddress,
    UserPassword   => 'password',
    ValidID        => 1,
    UserID         => 1,
);
$Self->True(
    $CustomerUserID,
    "CustomerUserID $CustomerUserID is created",
);

my @Tests = (
    {
        EmailAddress => 'Unknown' . $CustomerUserEmailAddress,
        Result       => {
            CustomerUserID => undef,
            CustomerID     => undef,
        },
    },
    {
        EmailAddress => $CustomerUserEmailAddress,
        Result       => {
            CustomerUserID => $CustomerUserID,
            CustomerID     => $CustomerCompanyID,
        },
    }
);

my ( $ExitCode, $Result );

{
    local *STDIN;
    open STDIN, '<:utf8', \'';    ## no critic
    $ExitCode = $CommandObject->Execute();
}

$Self->Is(
    $ExitCode,
    1,
    "Maint::PostMaster::Read exit code without email input",
);

# Run tests.
for my $Test (@Tests) {

    # Make sure the postmaster object will be recreated for each loop.
    $Kernel::OM->ObjectsDiscard(
        Objects => [
            'Kernel::System::PostMaster',
        ],
    );

    {
        my $Email = "From: $Test->{EmailAddress}\nTo: you\@home.com\nSubject: Test\nUnit tests rock.\n";
        local *STDIN;
        open STDIN, '<:utf8', \$Email;    ## no critic
        local *STDOUT;
        open STDOUT, '>:utf8', \$Result;    ## no critic
        $ExitCode = $CommandObject->Execute('--debug');
    }

    $Self->Is(
        $ExitCode,
        0,
        "Maint::PostMaster::Read exit code with email input",
    );

    my ($TicketID) = $Result =~ m{TicketID:\s+(\d+)};

    $Self->True(
        $TicketID,
        'Ticket is created from email',
    );

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $TicketID,
    );

    $Self->Is(
        $Ticket{CustomerID},
        $Test->{Result}->{CustomerID},
        "Ticket customer ID is expected",
    );
    $Self->Is(
        $Ticket{CustomerUserID},
        $Test->{Result}->{CustomerUserID},
        "Ticket customer user ID is expected",
    );
}

# Cleanup is done by RestoreDatabase.

1;
