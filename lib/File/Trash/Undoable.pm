package File::Trash::Undoable;

use 5.010;
use strict;
use warnings;

use File::Trash::FreeDesktop;
use Perinci::Sub::Gen 0.13 qw(gen_undoable_func);

# VERSION

our %SPEC;

#my $res = gen_undoable_func(
#    name => 'trash_files',
#    summary => 'Trash files (with undo support)',
#    args => {
#        files => {
#            args
#        },
#    },
#);
#$res->[0] == 200 or die "Can't generate function: $res->[0] - $res->[1]";

$SPEC{trash_files} = {
    # TODO: -v as alias to --verbose
};
sub trash_files {
    [200, "OK", "Placeholder for trash_files"];
}

$SPEC{list_trash_contents} = {
};
sub list_trash_contents {
    [200, "OK", "Placeholder for list_trash_contents"];
}

$SPEC{empty_trash} = {
};
sub empty_trash {
    [200, "OK", "Placeholder for empty_trash"];
}

1;
# ABSTRACT: Trash files (with undo support)

=head1 SYNOPSIS

 # use the u-trash, u-trash-empty script


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
