package Thesaurus::DBI;

use strict;
use vars qw[$VERSION @ISA];


$VERSION = (sprintf '%2d.%02d', q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/) - 1;
@ISA = qw(Thesaurus);

1;

sub new
{
    die "This doesn't do anything yet.  Sorry";
}

__END__

=head1 NAME

Thesaurus::DBI - Subclass of Thesaurus that creates data structure in a database.

=head1 SYNOPSIS

  use Thesaurus::DBI;

  my $thesaurus = Thesaurus::DBI( ignore_case => 1,
                                  configuration => 'myconfig',
                                  dbh => $dbh );

=head1 DESCRIPTION

This subclass of Thesaurus creates and maintains its data structure
inside a database.  Use the thesaurus_dbi_config.pl script to create a
configuration for Thesaurus::DBI.  This script creates and/or modifies
the Thesaurus::DBI::Config module, which contains configuration data
for your particular setup.  You can create and maintain multiple 

THIS SUBCLASS HAS NOT YET BEEN IMPLEMENTED!

=head1 METHODS

=over 4

=item * new(%params)

This method returns a new Thesaurus::DBI object using the
specified configuration.

This method takes the following parameters:

=item * ignore_case (0 or 1) - A boolean parameter.  If true, then the
object will be case insensitive.  It is _always_ case-preservative for
its data.

=item * configuration ($) - The name that identifies the configuration
you want to use.  This was specified in the thesaurus_dbi_config.pl
script.

=item * dbh ($) - This is an optional parameter which should be an
open database handle.  If this is not given then Thesaurus::DBI will
attempt to open a database handle based on information specified by
the configuration name.  However, you may not wish to store the
information necessary to open these handles (such as a password) in
the Thesaurus::DBI::Config module (which stores it in plaintext).  If
this parameter is given, then Thesaurus::DBI will not attempt to make
a database handle.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 SEE ALSO

Thesaurus, Thesaurus::File, Thesaurus::DBM

=cut
