# --
# AdminTemplateAttachment.t - frontend tests for AdminTemplateAttachment
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
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');

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

        my $AttachmentRandomID = "attachment" . $Helper->GetRandomID();
        my $TemplateRandomID   = "template" . $Helper->GetRandomID();

        # create test attachment
        $Selenium->get("${ScriptAlias}index.pl?Action=AdminAttachment");
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Add' )]")->click();

        my $Location = $ConfigObject->Get('Home')
            . "/scripts/test/sample/StdAttachment/StdAttachment-Test1.txt";

        $Selenium->find_element( "#Name",       'css' )->send_keys($AttachmentRandomID);
        $Selenium->find_element( "#FileUpload", 'css' )->send_keys($Location);
        $Selenium->find_element( "#Name",       'css' )->submit();

        # create test template
        $Selenium->get("${ScriptAlias}index.pl?Action=AdminTemplate");
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Add' )]")->click();

        $Selenium->find_element( "#Name", 'css' )->send_keys($TemplateRandomID);
        $Selenium->find_element( "#Name", 'css' )->submit();

        # check overview AdminTemplateAttachment screen
        $Selenium->get("${ScriptAlias}index.pl?Action=AdminTemplateAttachment");

        for my $ID (
            qw(Templates Attachments FilterTemplates FilterAttachments)
            )
        {
            my $Element = $Selenium->find_element( "#$ID", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();
        }

        # check for test template and test attachment on screen
        $Self->True(
            index( $Selenium->get_page_source(), $TemplateRandomID ) > -1,
            "$TemplateRandomID found on screen"
        );
        $Self->True(
            index( $Selenium->get_page_source(), $AttachmentRandomID ) > -1,
            "$AttachmentRandomID found on screen"
        );

        # get id's for created test Template and Attachment
        my $TemplateID = $Kernel::OM->Get('Kernel::System::StandardTemplate')->StandardTemplateLookup(
            StandardTemplate => $TemplateRandomID,
        );
        my $AttachmentID = $Kernel::OM->Get('Kernel::System::StdAttachment')->StdAttachmentLookup(
            StdAttachment => $AttachmentRandomID,
        );

        # test search filters
        $Selenium->find_element( "#FilterTemplates",   'css' )->send_keys($TemplateRandomID);
        $Selenium->find_element( "#FilterAttachments", 'css' )->send_keys($AttachmentRandomID);

        sleep 1;

        $Self->True(
            $Selenium->find_element("//a[contains(\@href, \'Subaction=Template;ID=$TemplateID' )]")->is_displayed(),
            "$TemplateRandomID found on screen with filter on",
        );

        $Self->True(
            $Selenium->find_element("//a[contains(\@href, \'Subaction=Attachment;ID=$AttachmentID' )]")->is_displayed(),
            "$AttachmentRandomID found on screen with filter on",
        );

        # change test Attachment relation for test Template
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Template;ID=$TemplateID' )]")->click();

        $Selenium->find_element("//input[\@value='$AttachmentID'][\@type='checkbox']")->click();
        $Selenium->find_element("//button[\@value='Submit'][\@type='submit']")->click();

        # check test Template relation for test Attachment
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Attachment;ID=$AttachmentID' )]")->click();

        $Self->True(
            $Selenium->find_element("//input[\@value='$TemplateID'][\@type='checkbox']")->is_selected(),
            "$AttachmentRandomID found on screen with filter on",
        );

        # Since there are no tickets that rely on our test TemplateAttachment,
        # we can remove test template and  test attchment from the DB
        my $Success = $DBObject->Do(
            SQL => "DELETE FROM standard_template_attachment WHERE standard_attachment_id = $AttachmentID",
        );
        $Self->True(
            $Success,
            "Deleted standard_template_attachment relation"
        );

        if ($TemplateRandomID) {
            my $Success = $DBObject->Do(
                SQL => "DELETE FROM standard_template WHERE id = $TemplateID",
            );
            $Self->True(
                $Success,
                "Deleted - $TemplateRandomID",
            );
        }
        if ($AttachmentRandomID) {
            my $Success = $DBObject->Do(
                SQL => "DELETE FROM standard_attachment WHERE id = $AttachmentID",
            );
            $Self->True(
                $Success,
                "Deleted - $AttachmentRandomID",
            );
        }

        # Make sure the cache is correct.
        for my $Cache (
            qw (StandardTemplate StandardAttachment)
            )
        {
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $Cache,
            );
        }

        }

);

1;
