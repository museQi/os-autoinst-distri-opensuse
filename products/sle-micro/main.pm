use strict;
use warnings;
use needle;
use File::Basename;
use scheduler 'load_yaml_schedule';
BEGIN {
    unshift @INC, dirname(__FILE__) . '/../../lib';
}
use utils;
use testapi;
use main_common;
use main_containers qw(load_container_tests is_container_test);
use version_utils qw(is_released);
use Utils::Architectures qw(is_s390x);

init_main();

my $distri = testapi::get_required_var('CASEDIR') . '/lib/susedistribution.pm';
require $distri;
testapi::set_distribution(susedistribution->new());

$needle::cleanuphandler = sub {
    unregister_needle_tags('ENV-BACKEND-ipmi');
    unregister_needle_tags('ENV-FLAVOR-JeOS-for-kvm');
    unregister_needle_tags('ENV-JEOS-1');
    unregister_needle_tags('ENV-OFW-0');
    unregister_needle_tags('ENV-OFW-1');
    unregister_needle_tags('ENV-UEFI-1') unless get_var('UEFI');
    unregister_needle_tags('ENV-PXEBOOT-0');
    unregister_needle_tags('ENV-PXEBOOT-1');
    unregister_needle_tags("ENV-DISTRI-sle");
    unregister_needle_tags("ENV-VERSION-15");
    unregister_needle_tags("ENV-VERSION-12");
    unregister_needle_tags("ENV-VERSION-12-SP1");
    unregister_needle_tags("ENV-VERSION-12-SP2");
    unregister_needle_tags("ENV-VERSION-12-SP3");
    unregister_needle_tags("ENV-VERSION-11-SP4");
    unregister_needle_tags("ENV-12ORLATER-1");
    unregister_needle_tags("ENV-FLAVOR-Server-DVD");
};

sub load_boot_from_disk_tests {
    if (is_s390x()) {
        loadtest 'installation/bootloader_start';
        loadtest 'boot/boot_to_desktop';
    } else {
        loadtest 'microos/disk_boot';
    }
    loadtest 'transactional/host_config';
    loadtest 'console/suseconnect_scc' if check_var('SCC_REGISTER', 'installation');
    loadtest 'transactional/enable_selinux' if get_var('ENABLE_SELINUX');
    loadtest 'transactional/install_updates' if is_released;
    loadtest 'microos/toolbox';
}

# Handle updates from repos defined in OS_TEST_TEMPLATE combined with the list
# of issues defined in OS_TEST_ISSUES.
# OS_TEST_ISSUES is set by openQABot and metadata repo used in maintenance
# (https://gitlab.suse.de/qa-maintenance/metadata)
# OS_TEST_TEMPLATE must be set at openQA job level.
# The array of repositories will be stored in MAINT_TEST_REPO for futher
# installation by the maintenance jobs.
if (is_updates_test_repo && !get_var('MAINT_TEST_REPO')) {
    my %incidents;
    my %u_url;
    $incidents{OS} = get_var('OS_TEST_ISSUES', '');
    $u_url{OS} = get_var('OS_TEST_TEMPLATE', '');

    my $repos = map_incidents_to_repo(\%incidents, \%u_url);
    set_var('MAINT_TEST_REPO', $repos);
}

return 1 if load_yaml_schedule;

if (is_container_test) {
    load_boot_from_disk_tests();
    load_container_tests();
}

1;
