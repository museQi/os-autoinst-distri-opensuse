# SUSE's openQA tests
#
# Copyright 2022 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: php8 timezone
# Summary: Basic timezone and php extra test, to make sure php timezone is consistent with the system one.
# Maintainer: QE Core <qe-core@suse.com>


use base "consoletest";
use strict;
use warnings;
use utils;
use testapi;
use apachetest;

my $date_time = "a";
my $php_time = "b";

sub compare_time {
    $date_time = script_output 'date +"%H:%M"';
    $php_time = script_output "php8 -r 'date_default_timezone_set(\"Europe/Berlin\");echo date(\"H:i\"), \"\n\";'";
    return ($date_time eq $php_time);
}

sub run {
    #Preparation
    my $self = shift;
    $self->select_serial_terminal;
    setup_apache2(mode => 'PHP8');

    #Save current timezone
    my $current_timezone = script_output 'timedatectl | grep "Time zone" | awk \'{print $3}\' ';

    #Set timezone
    assert_script_run 'timedatectl set-timezone Europe/Berlin';

    #Compare times (if first fails, try again to cover a possible minute change)
    if (compare_time() == 0) {
        if (compare_time() == 0) {
            #Cleanup and fail
            script_run "timedatectl set-timezone $current_timezone";
            die sprintf("Time from `date`: %s and `php date`: %s do not match", $date_time, $php_time);
        }
    }

    #Cleanup
    assert_script_run "timedatectl set-timezone $current_timezone";
}
1;
