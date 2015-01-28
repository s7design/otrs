# --
# AdminPackageManager.t - frontend tests for AdminPackageManager
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

use Kernel::System::UnitTest::Helper;
use Kernel::System::UnitTest::Selenium;

# get needed objects
my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

# get OTRS Version
my $OTRSVersion = $ConfigObject->Get('Version');

# leave only mayor and minor level versions
$OTRSVersion =~ s{ (\d+ \. \d+) .+ }{$1}msx;

# add x as patch level version
$OTRSVersion .= '.x';

my $String = '<?xml version="1.0" encoding="utf-8" ?>
<otrs_package version="1.0">
  <Name>Test</Name>
  <Version>0.0.1</Version>
  <Vendor>OTRS AG</Vendor>
  <URL>http://otrs.org/</URL>
  <License>GNU GENERAL PUBLIC LICENSE Version 2, June 1991</License>
  <ChangeLog>2005-11-10 New package (some test &lt; &gt; &amp;).</ChangeLog>
  <Description Lang="en">A test package (some test &lt; &gt; &amp;).</Description>
  <Description Lang="de">Ein Test Paket (some test &lt; &gt; &amp;).</Description>
  <ModuleRequired Version="1.112">Encode</ModuleRequired>
  <Framework>' . $OTRSVersion . '</Framework>
  <BuildDate>2005-11-10 21:17:16</BuildDate>
  <BuildHost>yourhost.example.com</BuildHost>
  <CodeInstall>
   # just a test &lt;some&gt; plus some &amp; text
  </CodeInstall>
  <DatabaseInstall>
    <TableCreate Name="test_package">
        <Column Name="name_a" Required="true" Type="INTEGER"/>
        <Column Name="name_b" Required="true" Size="60" Type="VARCHAR"/>
        <Column Name="name_c" Required="false" Size="60" Type="VARCHAR"/>
    </TableCreate>
    <Insert Table="test_package">
        <Data Key="name_a">1234</Data>
        <Data Key="name_b" Type="Quote">some text</Data>
        <Data Key="name_c" Type="Quote">some text &lt;more&gt;
          text &amp; text
        </Data>
    </Insert>
    <Insert Table="test_package">
        <Data Key="name_a">0</Data>
        <Data Key="name_b" Type="Quote">1</Data>
    </Insert>
  </DatabaseInstall>
  <DatabaseUninstall>
    <TableDrop Name="test_package"/>
  </DatabaseUninstall>
  <Filelist>
    <File Location="Test" Permission="644" Encode="Base64">aGVsbG8K</File>
    <File Location="var/Test" Permission="644" Encode="Base64">aGVsbG8K</File>
  </Filelist>
</otrs_package>
';

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

        my $ScriptAlias = $ConfigObject->Get('ScriptAlias');

        $Selenium->get("${ScriptAlias}index.pl?Action=AdminPackageManager");

        my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

        my $PackageInstall = $PackageObject->PackageInstall( String => $String );

        my $Download = $PackageObject->PackageOnlineGet(
            Source => 'http://ftp.otrs.org/pub/otrs/packages',
            File   => 'Support-1.4.4.opm',
        );

        $Self->True(
            $Download,
            "PackageOnlineGet - get Support package from ftp.otrs.org",
        );

        $Self->True(
            $PackageInstall,
            'PackageInstall() - Package Test',
        );

        $Selenium->refresh();

        $Selenium->find_element(
            "//a[contains(\@href, \'Subaction=View;Name=Test' )]"
        )->click();

        $Selenium->go_back();

        $Selenium->find_element(
            "//a[contains(\@href, \'Subaction=Uninstall;Name=Test' )]"
        )->click();

        $Selenium->find_element( "//button[\@value='Uninstall package'][\@type='submit']")->click();



    my $Data = $Selenium->screenshot();
    if ($Data ){
        $Data = MIME::Base64::decode_base64($Data);

        # This file should survive unit test scenario runs, so save it in a global directory.
        my ( $FH, $Filename ) = File::Temp::tempfile(
            DIR    => '/tmp/',
            SUFFIX => '.png',
            UNLINK => 0,
        );
        close $FH;
        $Kernel::OM->Get('Kernel::System::Main')->FileWrite(
            Location => $Filename,
            Content  => \$Data,
        );

        $Self->True(
            1,
            "Saved screenshot in file://$Filename",
        );
    }



        }
);

1;
