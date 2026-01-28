#!/usr/bin/perl -w

use POSIX qw(strftime);

system('git submodule foreach git checkout -f err0/initial') == 0 || die '[SOAK-1] unable to checkout initial branches.';

# Cross-platform UUID generation
# On Linux with /proc/sys/kernel/random/uuid, read from there
# Otherwise use uuidgen command (macOS, Windows with Git Bash)
my $branch_uuid;
if ($^O eq 'linux' && -f '/proc/sys/kernel/random/uuid') {
    open(my $fh, '<', '/proc/sys/kernel/random/uuid') or die "Cannot read /proc/sys/kernel/random/uuid: $!";
    $branch_uuid = <$fh>;
    close($fh);
} else {
    $branch_uuid = `uuidgen`;
}
chomp($branch_uuid);

my $tag_uuid;
if ($^O eq 'linux' && -f '/proc/sys/kernel/random/uuid') {
    open(my $fh, '<', '/proc/sys/kernel/random/uuid') or die "Cannot read /proc/sys/kernel/random/uuid: $!";
    $tag_uuid = <$fh>;
    close($fh);
} else {
    $tag_uuid = `uuidgen`;
}
chomp($tag_uuid);

$branch = 'err0/' . strftime('%Y%m%d%H%M', localtime) . '-' . $branch_uuid;
$tag = 'err0-tag-' . $tag_uuid;
$atag = 'err0-atag-' . $tag_uuid;

# Function to find token file using config-helper.sh
# Maintains backward compatibility with dev-localhost/
sub find_token {
    my $project = shift;

    # Use bash to source config-helper.sh and call find_token_file
    my $token = `bash -c 'source scripts/config-helper.sh 2>/dev/null && find_token_file "$project" 2>/dev/null'`;
    chomp($token);

    # Fallback to dev-localhost if dynamic discovery fails
    if (!$token || !-f $token) {
        my @legacy_tokens = glob("dev-localhost/err0-$project-*.json");
        if (@legacy_tokens) {
            $token = $legacy_tokens[0];
        } else {
            die "ERROR: No token found for project '$project'. " .
                "Expected in tokens/ or dev-localhost/ directory.\n";
        }
    }

    return $token;
}

system('git submodule foreach git branch ' . $branch) == 0 || die '[SOAK-2] unable to create branch for test run.';

system('git submodule foreach git checkout -f ' . $branch) == 0 || die '[SOAK-3] unable to checkout test branch ' . $branch . ' for test run.';

system('./err0agent-localdev-insert.sh ' . find_token('django') . ' django') == 0 || die '[DEV-1001] django insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('kubernetes') . ' kubernetes') == 0 || die '[DEV-1002] kubernetes insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('magento2') . ' magento2') == 0 || die '[DEV-1003] magento2 insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('moodle') . ' moodle') == 0 || die '[DEV-1004] moodle insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('NodeBB') . ' NodeBB') == 0 || die '[DEV-1005] NodeBB insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('roslyn') . ' roslyn') == 0 || die '[DEV-1006] roslyn insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('spring-framework') . ' spring-framework') == 0 || die '[DEV-1007] spring-framework insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Umbraco-CMS') . ' Umbraco-CMS') == 0 || die '[DEV-1008] Umbraco-CMS insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('zf2-orders') . ' zf2-orders') == 0 || die '[DEV-1009] zf2-orders insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('drupal') . ' drupal') == 0 || die '[DEV-1010] drupal insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('tomcat') . ' tomcat') == 0 || die '[DEV-1011] tomcat insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('WordPress') . ' WordPress') == 0 || die '[DEV-1012] WordPress insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('ratpack') . ' ratpack') == 0 || die '[DEV-1013] ratpack insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('strapi') . ' strapi') == 0 || die '[DEV-1014] strapi insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('cerbos') . ' cerbos') == 0 || die '[DEV-1015] cerbos insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('mender') . ' mender') == 0 || die '[DEV-1016] mender insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('pytorch') . ' pytorch') == 0 || die '[DEV-1017] pytorch insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('postfix') . ' postfix') == 0 || die '[DEV-1018] postfix insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('bitcoin') . ' bitcoin') == 0 || die '[DEV-1019] bitcoin insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('leptos') . ' leptos') == 0 || die '[DEV-1020] leptos insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('servo') . ' servo') == 0 || die '[DEV-1021] servo insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('SmartThingsEdgeDrivers') . ' SmartThingsEdgeDrivers') == 0 || die '[DEV-1022] SmartThingsEdgeDrivers insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('rails') . ' rails') == 0 || die '[DEV-1023] Rails insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('vapor') . ' vapor') == 0 || die '[DEV-1024] Vapor insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('UTM') . ' UTM') == 0 || die '[DEV-1025] UTM insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Signal-iOS') . ' Signal-iOS') == 0 || die '[DEV-1026] Signal-iOS insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Telegram-iOS') . ' Telegram-iOS') == 0 || die '[DEV-1027] Telegram-iOS insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Signal-Android') . ' Signal-Android') == 0 || die '[DEV-1028] Signal-Android insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Telegram') . ' Telegram') == 0 || die '[DEV-1029] Telegram insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('ktor') . ' ktor') == 0 || die '[DEV-1030] ktor insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('kotlinx.html') . ' kotlinx.html') == 0 || die '[DEV-1031] kotlinx.html insert failed.';

system('git submodule foreach git add .') == 0 || die '[SOAK-4] unable to stage changes after insert pass #1';

system('git submodule foreach git commit -m "err0 pass"') == 0 || die '[SOAK-5] unable to commit changes after insert pass #1';

system('git submodule foreach git tag ' . $tag) == 0 || die '[SOAK-9] unable to tag changes after insert pass #1';
system('git submodule foreach git tag -a -m err0-message ' . $atag) == 0 || die '[SOAK-10] unable to create annotated tag for changes after insert pass #1';

# analyse run, finalises codes, but also, checks that all codes are canonical.

system('./err0agent-localdev-check.sh ' . find_token('django') . ' django') == 0 || die '[DEV-2001] django analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('kubernetes') . ' kubernetes') == 0 || die '[DEV-2002] kubernetes analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('magento2') . ' magento2') == 0 || die '[DEV-2003] magento2 analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('moodle') . ' moodle') == 0 || die '[DEV-2004] moodle analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('NodeBB') . ' NodeBB') == 0 || die '[DEV-2005] NodeBB analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('roslyn') . ' roslyn') == 0 || die '[DEV-2006] roslyn analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('spring-framework') . ' spring-framework') == 0 || die '[DEV-2007] spring-framework analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('Umbraco-CMS') . ' Umbraco-CMS') == 0 || die '[DEV-2008] Umbraco-CMS analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('zf2-orders') . ' zf2-orders') == 0 || die '[DEV-2009] zf2-orders analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('drupal') . ' drupal') == 0 || die '[DEV-2010] drupal analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('tomcat') . ' tomcat') == 0 || die '[DEV-2011] tomcat analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('WordPress') . ' WordPress') == 0 || die '[DEV-2012] WordPress analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('ratpack') . ' ratpack') == 0 || die '[DEV-2013] ratpack analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('strapi') . ' strapi') == 0 || die '[DEV-2014] strapi analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('cerbos') . ' cerbos') == 0 || die '[DEV-2015] cerbos analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('mender') . ' mender') == 0 || die '[DEV-2016] mender analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('pytorch') . ' pytorch') == 0 || die '[DEV-2017] pytorch analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('postfix') . ' postfix') == 0 || die '[DEV-2018] postfix analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('bitcoin') . ' bitcoin') == 0 || die '[DEV-2019] bitcoin analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('leptos') . ' leptos') == 0 || die '[DEV-2020] leptos analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('servo') . ' servo') == 0 || die '[DEV-2021] servo analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('SmartThingsEdgeDrivers') . ' SmartThingsEdgeDrivers') == 0 || die '[DEV-2022] SmartThingsEdgeDrivers analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('rails') . ' rails') == 0 || die '[DEV-2023] Rails analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('vapor') . ' vapor') == 0 || die '[DEV-2024] Vapor analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('UTM') . ' UTM') == 0 || die '[DEV-2025] UTM analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('Signal-iOS') . ' Signal-iOS') == 0 || die '[DEV-2026] Signal-iOS analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('Telegram-iOS') . ' Telegram-iOS') == 0 || die '[DEV-2027] Telegram-iOS analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('Signal-Android') . ' Signal-Android') == 0 || die '[DEV-2028] Signal-Android analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('Telegram') . ' Telegram') == 0 || die '[DEV-2029] Telegram analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('ktor') . ' ktor') == 0 || die '[DEV-2030] ktor analyse failed.';
system('./err0agent-localdev-check.sh ' . find_token('kotlinx.html') . ' kotlinx.html') == 0 || die '[DEV-2031] kotlinx.html analyse failed.';

# second insert pass, are there more codes to insert?

system('./err0agent-localdev-insert.sh ' . find_token('django') . ' django') == 0 || die '[DEV-3001] django insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('kubernetes') . ' kubernetes') == 0 || die '[DEV-3002] kubernetes insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('magento2') . ' magento2') == 0 || die '[DEV-3003] magento2 insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('moodle') . ' moodle') == 0 || die '[DEV-3004] moodle insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('NodeBB') . ' NodeBB') == 0 || die '[DEV-3005] NodeBB insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('roslyn') . ' roslyn') == 0 || die '[DEV-3006] roslyn insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('spring-framework') . ' spring-framework') == 0 || die '[DEV-3007] spring-framework insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Umbraco-CMS') . ' Umbraco-CMS') == 0 || die '[DEV-3008] Umbraco-CMS insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('zf2-orders') . ' zf2-orders') == 0 || die '[DEV-3009] zf2-orders insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('drupal') . ' drupal') == 0 || die '[DEV-3010] drupal insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('tomcat') . ' tomcat') == 0 || die '[DEV-3011] tomcat insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('WordPress') . ' WordPress') == 0 || die '[DEV-3012] WordPress insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('ratpack') . ' ratpack') == 0 || die '[DEV-3013] ratpack insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('strapi') . ' strapi') == 0 || die '[DEV-3014] strapi insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('cerbos') . ' cerbos') == 0 || die '[DEV-3015] cerbos insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('mender') . ' mender') == 0 || die '[DEV-3016] mender insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('pytorch') . ' pytorch') == 0 || die '[DEV-3017] pytorch insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('postfix') . ' postfix') == 0 || die '[DEV-3018] postfix insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('bitcoin') . ' bitcoin') == 0 || die '[DEV-3019] bitcoin insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('leptos') . ' leptos') == 0 || die '[DEV-3020] leptos insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('servo') . ' servo') == 0 || die '[DEV-3021] servo insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('SmartThingsEdgeDrivers') . ' SmartThingsEdgeDrivers') == 0 || die '[DEV-3022] SmartThingsEdgeDrivers insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('rails') . ' rails') == 0 || die '[DEV-3023] Rails insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('vapor') . ' vapor') == 0 || die '[DEV-3024] Vapor insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('UTM') . ' UTM') == 0 || die '[DEV-3025] UTM insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Signal-iOS') . ' Signal-iOS') == 0 || die '[DEV-3026] Signal-iOS insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Telegram-iOS') . ' Telegram-iOS') == 0 || die '[DEV-3027] Telegram-iOS insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Signal-Android') . ' Signal-Android') == 0 || die '[DEV-3028] Signal-Android insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('Telegram') . ' Telegram') == 0 || die '[DEV-3029] Telegram insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('ktor') . ' ktor') == 0 || die '[DEV-3030] ktor insert failed.';
system('./err0agent-localdev-insert.sh ' . find_token('kotlinx.html') . ' kotlinx.html') == 0 || die '[DEV-3031] kotlinx.html insert failed.';

$changes = 0;
$text = '';

open(my $fh, '-|', 'git submodule foreach git status --porcelain') or die '[SOAK-6] opening git status - are there changes?';
while (my $line = <$fh>) {
    if ($line =~ /^Entering/) { next; }
    $changes++;
    $text .= $line;
}
close($fh);

if ($changes > 0) {
    die '[SOAK-7] changes on second import run:\n' . $text;
}

# after second insert run, check that there is nothing to commit, e.g. pass 2 = pass 1 :-)
#
# git submodule foreach git status --porcelain
#  M django/views/generic/dates.py
#  M django/views/generic/detail.py
#  M django/views/generic/edit.py
#  M django/views/generic/list.py
#  M django/views/static.py
# Entering 'kubernetes'
#
# - skip lines starting with Entering
# - if # count of other lines is non zero then there are changes, else the entire set of submodules are clean.

exit 0;