package File::Trash::Undoable;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use Cwd qw(abs_path);
use File::Trash::FreeDesktop 0.05;
use Perinci::Sub::Gen::Undoable 0.24 qw(gen_undoable_func);

# VERSION

our %SPEC;

my $trash = File::Trash::FreeDesktop->new;

my $res;

$res = gen_undoable_func(
    v => 2,
    name => 'trash',
    summary => 'Trash a file',
    args => {
        path => {
            schema => 'str*',
        },
    },
    description => <<'_',

Fixed state: path does not exist.

Fixable state: path exists.

_
    check_args => sub {
        # TMP, schema
        my $args = shift;
        defined($args->{path}) or return [400, "Please specify path"];
        [200, "OK"];
    },
    check_or_fix_state => sub {
        my ($which, $args, $step) = @_;

        #my $do_log   = !$args->{-check_state};
        my $path     = $args->{path};
        my $exists   = (-l $path) || (-e _);

        my @u;
        if ($which eq 'check') {
            if ($exists) {
                push @u, [__PACKAGE__.'::untrash', {path => $path}];
            }
            return @u ? [200,"OK",undef,{undo_data=>\@u}]:[304,"Nothing to do"];
        }
        $log->info("Trashing $path ...");
        eval { $trash->trash($path) };
        return $@ ? [500, "trash() failed: $@"] : [200, "OK"];
    }
);
$res->[0] == 200 or die "Can't generate untrash(): $res->[0] - $res->[1]";

$res = gen_undoable_func(
    v => 2,
    name => 'untrash',
    summary => 'Untrash a file',
    description => <<'_',

Fixed state: path exists.

Fixable state: Path does not exist (and entry for path is contained in trash;
this bit is currently not implemented).

_
    check_or_fix_state => sub {
        my ($which, $args, $undo) = @_;

        #my $do_log   = !$args->{-check_state};
        my $path     = $args->{path};
        my $exists   = (-l $path) || (-e _);

        my @u;
        if ($which eq 'check') {
            if (!$exists) {
                push @u, [__PACKAGE__.'::trash', {path => $path}];
            }
            return @u ? [200,"OK",undef,{undo_data=>\@u}]:[304,"Nothing to do"];
        }
        $log->info("Untrashing $path ...");
        #eval { $trash->recover({on_target_exists=>'ignore', on_not_found=>'ignore'}, $path) };
        eval { $trash->recover($path) };
        return $@ ? [500, "untrash() failed: $@"] : [200, "OK"];
    },
);
$res->[0] == 200 or die "Can't generate untrash(): $res->[0] - $res->[1]";

$res = gen_undoable_func(
    v => 2,
    name => 'trash_files',
    summary => 'Trash files (with undo support)',
    req_tx => 1,
    args => {
        files => {
            summary => 'Files/dirs to delete',
            description => <<'_',

Files must exist.

_
            schema => ['array*' => {of=>'str*'}],
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
    check_args => sub {
        my $args = shift;
        my $ff   = $args->{files};
        $ff or return [400, "Please specify files"];
        ref($ff) eq 'ARRAY' or return [400, "Files must be array"];
        @$ff > 0 or return [400, "Please specify at least 1 file"];
        for (@$ff) {
            (-l $_) || (-e _) or return [400, "File does not exist: $_"];
            my $orig = $_;
            $_ = abs_path($_);
            $_ or return [400, "Can't convert to absolute path: $orig"];
        }
        [200, "OK"];
    },
    check_or_fix_state => sub {
        my ($which, $args, $undo) = @_;

        my $ff = $args->{files};
        my $tm = $args->{-tx_manager};

        my @u;
        if ($which eq 'check') {
            push @u, [__PACKAGE__."::untrash", {path=>$_}]
                for @$ff;
            return @u ? [200,"OK",undef,{undo_data=>\@u}]:[304,"Nothing to do"];
        } else {
            $tm->_empty_undo_data;
            return $tm->call(calls => [
                map { [__PACKAGE__."::trash", {path=>$_}] } @$ff ]);
        }
    },
);
$res->[0] == 200 or die "Can't generate trash_files(): $res->[0] - $res->[1]";

$SPEC{list_trash_contents} = {
    summary => 'List contents of trash directory',
};
sub list_trash_contents {
    my %args = @_;
    [200, "OK", [$trash->list_contents]];
}

$SPEC{empty_trash} = {
    summary => 'Empty trash',
};
sub empty_trash {
    my %args = @_;
    my $cmd  = $args{-cmdline};

    $trash->empty;
    if ($cmd) {
        $cmd->run_clear_history;
        return $cmd->{_res};
    } else {
        [200, "OK"];
    }
}

1;
# ABSTRACT: Trash files (with undo support)

=head1 SYNOPSIS

 # use the trash-u script


=head1 DESCRIPTION

This module provides routines to trash files, with undo/redo support. Originally
written to demonstrate/test L<Perinci::Sub::Gen::Undoable>.


=head1 SEE ALSO

=over 4

=item * B<gvfs-trash>

A command-line utility, part of the GNOME project.

=item * B<trash-cli>, https://github.com/andreafrancia/trash-cli

A Python-based command-line application. Also follows freedesktop.org trash
specification.

=item * B<rmv>, http://code.google.com/p/rmv/

A bash script. Features undo ("rollback"). At the time of this writing, does not
support per-filesystem trash (everything goes into home trash).

=back

=cut
