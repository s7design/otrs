# --
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

# get selenium object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Selenium' => {
        Verbose => 1,
        }
);
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::UnitTest::Helper' => {
                RestoreSystemConfiguration => 0,
                }
        );
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get sys config object
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        # do not check service and type
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Service',
            Value => 0
        );
        $SysConfigObject->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Type',
            Value => 0
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users', 'stats' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');
        $Selenium->get("${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=Import");

        # import test selenium statistic
        my $Location = $Kernel::OM->Get('Kernel::Config')->Get('Home')
            . "/scripts/test/sample/Stats/Stats.TicketOverview.de.xml";
        $Selenium->find_element( "#File", 'css' )->send_keys($Location);
        $Selenium->find_element("//button[\@value='Import'][\@type='submit']")->click();

        # create params for import test stats
        my %StatsValues = (
            Title       => 'Überblick über alle Tickets im System',
            Object      => 'Ticket',
            Description => 'Aktueller Status aller im System befindlicher Tickets ohne Zeitbeschränkung.',
            Format      => 'D3::MultiBarChart',
        );

        # check for imported values on test stat
        for my $StatsValue ( sort keys %StatsValues ) {
            $Self->True(
                index( $Selenium->get_page_source(), $StatsValues{$StatsValue} ) > -1,
                "Expexted param $StatsValue for imported stat is founded - $StatsValues{$StatsValue}"
            );
        }

        # navigate to AgentStatistics Overview screen
        $Selenium->get(
            "${ScriptAlias}index.pl?Action=AgentStatistics;Subaction=Overview;"
        );

        # get stats object
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::Stats' => {
                UserID => 1,
                }
        );
        my $StatsObject = $Kernel::OM->Get('Kernel::System::Stats');

        # get stats IDs
        my $StatsIDs = $StatsObject->GetStatsList(
            AccessRw => 1,
        );

        my $Count       = scalar @{$StatsIDs};
        my $StatsIDLast = $StatsIDs->[ $Count - 1 ];

        # check for imported stats on overview screen
        $Self->True(
            index( $Selenium->get_page_source(), $StatsValues{Title} ) > -1,
            "Imported stat $StatsValues{Title} - found on overview screen"
        );

        # go to imported stat to run it
        $Selenium->find_element("//a[contains(\@href, \'AgentStatistics;Subaction=Edit;StatID=$StatsIDLast\' )]")
            ->click();

        $Selenium->WaitFor( JavaScript => 'return $(".EditXAxis").length' );

        # change preview format to Print
        $Selenium->find_element("//button[contains(\@data-format, \'Print')]")->click();

        $Self->True(
            $Selenium->execute_script("return \$('#PreviewContentPrint').css('display')") eq 'block',
            "Print format is displayed",
        );
        $Self->True(
            $Selenium->execute_script("return \$('#PreviewContentBar').css('display')") eq 'none',
            "Bar format is not displayed",
        );

        # change preview format to Bar
        $Selenium->find_element("//button[contains(\@data-format, \'D3::MultiBarChart')]")->click();

        $Self->True(
            $Selenium->execute_script("return \$('#PreviewContentBar').css('display')") eq 'block',
            "Bar format is displayed",
        );
        $Self->True(
            $Selenium->execute_script("return \$('#PreviewContentPrint').css('display')") eq 'none',
            "Print format is not displayed",
        );

        # toggle General Specification
        $Selenium->find_element("//a[contains(\@aria-controls, \'Core_UI_AutogeneratedID_1')]")->click();
        $Selenium->find_element( "#Title",      'css' )->send_keys(" - Updated");

        # check X-axis configuration dialog
        $Selenium->find_element( ".EditXAxis", 'css' )->click();
        $Selenium->find_element( "#EditDialog a.RemoveButton i",      'css' )->click();
        $Selenium->find_element( "#EditDialog select option[value='XAxisServiceIDs']", 'css' )->click();
        $Selenium->find_element( "#DialogButton1", 'css' )->click();

        # check Y-axis configuration dialog
        $Selenium->find_element( ".EditYAxis", 'css' )->click();
        $Selenium->find_element( "#EditDialog a.RemoveButton i",      'css' )->click();
        $Selenium->find_element( "#EditDialog select option[value='YAxisSLAIDs']", 'css' )->click();
        $Selenium->find_element( "#DialogButton1", 'css' )->click();

        # check Restrictions configuration dialog
        $Selenium->find_element( ".EditRestrictions", 'css' )->click();
        $Selenium->find_element( "#EditDialog select option[value='RestrictionsQueueIDs']", 'css' )->click();
        $Selenium->find_element( "#DialogButton1", 'css' )->click();

        # save and finish edit
        $Selenium->find_element("//button[\@name='SaveAndFinish'][\@type='submit']")->click();

  my $CheckConfirmJS = <<"JAVASCRIPT";
(function () {
    var lastConfirm = undefined;
    window.confirm = function (message) {
        lastConfirm = message;
        return true;
    };
}());
JAVASCRIPT

        $Selenium->execute_script($CheckConfirmJS);

        # delete imported test stats
        # click on delete icon
        $Selenium->find_element(
            "//a[contains(\@href, \'Action=AgentStatistics;Subaction=DeleteAction;StatID=$StatsIDLast\' )]"
        )->click();

        $Selenium->WaitFor( JavaScript => 'return $(".Dialog:visible").length === 0;' );

        $Self->True(
            index( $Selenium->get_page_source(), "Action=AgentStatistics;Subaction=Edit;StatID=$StatsIDLast" ) == -1,
            "Test statistic is deleted - $StatsIDLast "
        );

        # make sure the cache is correct.
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => "Stats" );
    }
);

1;
