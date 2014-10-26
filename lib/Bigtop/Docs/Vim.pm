package Bigtop::Docs::Vim;

=head1 Name

Bigtop::Docs::Vim - How to get vim syntax things for Bigtop files

=head1 How To

There are syntax files for vim in the Bigtop distribution's vim subdirectory.
To use them do the following:

=over 4

=item 1

Create a .vim directory under your home directory, if you don't already have
one.

=item 2

Copy filetype.vim to the new directory, or merge it with the one you already
have.

=item 3

Create a subdirectory of .vim called syntax, if you don't already have one.

=item 4

Copy bigtop.vim to the syntax subdirectory.

=item 5

Start vim on a bigtop file and see the pretty colors.

=back

You could also just cp -R * from the Bigtop vim directory into
your .vim directory and skip to step 5, but that would overwrite your
filetype.vim, if you have one.

=head1 Folding

If you want folding, add:

    let bigtop_fold=1

to your .vimrc.  This will fold all brace delimited blocks.

=cut
