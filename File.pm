package Thesaurus::File;

use strict;
use vars qw[$VERSION @ISA];

use Thesaurus;

use Carp;
use Text::CSV_XS;
use IO::File;

$VERSION = (sprintf '%2d.%02d', q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/) - 1;
@ISA = qw(Thesaurus);

1;

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = $class->SUPER::new(@_);

    bless $self, $class;

    $self->{csv} = Text::CSV_XS->new( { binary => 1 } );

    if (exists $self->{params}{files})
    {
	( ref $self->{params}{files} ?
	  $self->add_files( @{ $self->{params}{files} } ) :
	  $self->add_files( $self->{params}{files} ) );
    }

    return $self;
}

sub add_files
{
    my $self = shift;

    return unless @_;

    foreach my $file (@_)
    {
	my $fh = IO::File->new($file) or croak "can't open $file: $!";

	while (not $fh->eof)
	{
	    my $cols = $self->{csv}->getline($fh);

	    croak "Text::CSV_XS can't parse ", $self->{csv}->error_input
		unless defined $cols;
	    $self->add($cols);
	}

	$fh->close;
    }
}

sub save
{
    my $self = shift;
    my %params = @_;

    my $mode = $params{mode} eq 'append' ? '>>' : '>';

    my $fh = IO::File->new("$mode$params{filename}")
	or croak "can't open $params{filename} in $params{mode} mode: $!";

    my %written;
    foreach my $key (keys %{ $self->{data} })
    {
	next if $written{$key};

	$self->{csv}->print($fh, $self->{data}{$key});
	$fh->print("\n");

	map {$written{$_} = 1} @{ $self->{data}{$key} };
    }

    $fh->close;
}

__END__

=head1 NAME

Thesaurus::File - Subclass of Thesaurus that implements persistence
using CSV format text files.

=head1 SYNOPSIS

  use Thesaurus::File;

  my $book = Thesaurus->new( ignore_case => 1,
                             files => ['file1.csv', 'file2.csv'] );

=head1 DESCRIPTION

This subclass of Thesaurus implements persistence through the use of
CSV format text files.

=head1 METHODS

=item * add_files

 $th->add_files($filename1, $filenam2, ...);

This method adds the contents of the given files to the thesaurus
object.  If an entry in the files matches an entry already in the
object, then it is appended to the existing list, otherwise a new
entry is created.

=item * save(%params)

Writes the contents of the object to a CSV format file.  It takes the
following named parameters:

=item * filename ($) - The filename where the data will be written.

=item * mode ($) - This determines whether to write or append the
data.  This should be a string ('write' or 'append').

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 SEE ALSO

Thesaurus, Thesaurus::DBM, Thesaurus::DBI

=head1 COPYRIGHT

Copyright (c) 1999 David Rolsky. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
