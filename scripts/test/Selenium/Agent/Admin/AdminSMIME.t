# --
# AdminSMIME.t - frontend tests for AdminSMIME
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));
use File::Path qw(mkpath rmtree);

use Kernel::System::UnitTest::Helper;
use Kernel::System::UnitTest::Selenium;

# get needed objects
my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

my $Selenium = Kernel::System::UnitTest::Selenium->new(
    Verbose => 1,
);

$Selenium->RunTest(
    sub {

        my $Helper = Kernel::System::UnitTest::Helper->new(
            RestoreSystemConfiguration => 0,
        );

        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # enable SMIME in config
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'SMIME',
            Value => 1
        );

        # create directory for certificates and private keys
        my $CertPath    = $ConfigObject->Get('Home') . "/var/tmp/certs";
        my $PrivatePath = $ConfigObject->Get('Home') . "/var/tmp/private";
        mkpath( [$CertPath],    0, 0770 );    ## no critic
        mkpath( [$PrivatePath], 0, 0770 );    ## no critic

        # set SMIME paths in sysConfig
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'SMIME::CertPath',
            Value => $CertPath,
        );
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'SMIME::PrivatePath',
            Value => $PrivatePath,
        );

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        $Selenium->get("${ScriptAlias}index.pl?Action=AdminSMIME");

        # check overview screen
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );
        $Selenium->find_element( "#FilterSMIME",      'css' );

        # click 'Add Certificate'
        $Selenium->find_element("//a[contains(\@href, \'Subaction=ShowAddCertificate' )]")->click();

        my $CertLocation = $ConfigObject->Get('Home')
            . "/scripts/test/sample/SMIME/SMIMECertificate-smimeuser1.crt";

        $Selenium->find_element( "#FileUpload", 'css' )->send_keys($CertLocation);
        $Selenium->find_element("//button[\@type='submit']")->click();

        # click 'Add private key'
        $Selenium->find_element("//a[contains(\@href, \'Subaction=ShowAddPrivate' )]")->click();

        my $PrivateLocation = $ConfigObject->Get('Home')
            . "/scripts/test/sample/SMIME/SMIMEPrivateKey-smimeuser1.pem";

        $Selenium->find_element( "#FileUpload", 'css' )->send_keys($PrivateLocation);
        $Selenium->find_element( "#Secret",     'css' )->send_keys("secret");
        $Selenium->find_element("//button[\@type='submit']")->click();

        # check for test created Certificate and Privatekey and delete them
        for my $TestSMIME (qw(key cert))
        {
            $Self->True(
                index( $Selenium->get_page_source(), "Type=$TestSMIME;Filename=4d400195" ) > -1,
                "Test $TestSMIME SMIME found on table"
            );
            $Selenium->find_element("//a[contains(\@href, \'Subaction=Delete;Type=$TestSMIME;Filename=4d400195' )]")
                ->click();
        }

        # disable SMIME and restore default values to SMIME paths
        for my $SysRestore (
            qw (SMIME SMIME::CertPath SMIME::PrivatePath)
            )
        {
            $SysConfigObject->ConfigItemReset(
                Name => $SysRestore,
            );
        }

        # delete needed test directories
        for my $Directory ( $CertPath, $PrivatePath ) {
            my $Success = rmtree( [$Directory] );
            $Self->True(
                $Success,
                "Directory deleted - '$Directory'",
            );
        }

        }

);

1;
