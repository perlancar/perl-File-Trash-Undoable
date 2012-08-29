#!perl

use 5.010;
use autodie;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use File::chdir;
use File::Path qw(make_path remove_tree);
use File::Slurp;
use File::Temp qw(tempdir);
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
$ENV{HOME} = $tmpdir;
make_path "$tmpdir/.local/share/Trash/info", "$tmpdir/.local/share/Trash/files";

require File::Trash::Undoable; # so our changing HOME takes effect

test_tx_action(
    name        => "fixed (path doesn't exist)",
    tmpdir      => $tmpdir,
    f           => 'File::Trash::Undoable::trash',
    args        => {path=>"p"},
    reset_state => sub {
        remove_tree "p";
    },
    status      => 304,
);

test_tx_action(
    name        => "fixable (dir)",
    tmpdir      => $tmpdir,
    f           => 'File::Trash::Undoable::trash',
    args        => {path=>"p"},
    reset_state => sub {
        remove_tree "p";
        mkdir "p";
    },
    after_do    => sub {
        ok(!(-e "p"), "p deleted");
    },
    after_undo  => sub {
        ok((-d "p"), "p restored");
    },
);

test_tx_action(
    name        => "fixable (file)",
    tmpdir      => $tmpdir,
    f           => 'File::Trash::Undoable::trash',
    args        => {path=>"p"},
    reset_state => sub {
        remove_tree "p";
        write_file "p", "";
    },
    after_do    => sub {
        ok(!(-e "p"), "p deleted");
    },
    after_undo  => sub {
        ok((-f "p"), "p restored");
    },
);

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
