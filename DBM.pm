package Thesaurus::DBM;

use strict;
use vars qw[$VERSION @ISA];

use Thesaurus;

$VERSION = (sprintf '%2d.%02d', q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/) - 1;
@ISA = qw(Thesaurus);

1;

# use MLDBM with appropriate parameters.
sub import
{
    my $ev_string = 'use MLDBM ';

    shift;
    if (@_)
    {
	$ev_string .= 'qw(';
	$ev_string .= join ' ', @_;
	$ev_string .= ');';
    }

    eval $ev_string;
    die $@ if $@;
}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $self = $class->SUPER::new(%params);

    bless $self, $class;

    $self->{params} = \%params;

    $self->{params}{extra} ||= [];

    # This is to designed to support both the standard AnyDBM_File
    # syntax and the BerkeleyDB module syntax.
    my @params;
    push @params, $self->{params}{filename} if defined $self->{params}{filename};
    push @params, $self->{params}{flags} if defined $self->{params}{flags};
    push @params, $self->{params}{mode} if defined $self->{params}{mode};
    push @params, @{ $self->{params}{extra} };

    my %hash;
    my $tied_obj = tie %hash, 'MLDBM', @params
	or die "can't tie hash to MLDBM: $!";

    $self->{data} = \%hash;
    $self->{tied_obj} = $tied_obj;
    $self->{th} = Thesaurus->new(%params);

    foreach my $key (keys %{ $self->{data} })
    {
	$self->{th}->add( $self->{data}{$key} );
    }

    return $self;
}

sub add
{
    my $self = shift;

    # Lock it somehow?

    $self->{th}->add(@_);

    $self->_reserialize;

    # Unlock it somehow!
}

sub _reserialize
{
    my $self = shift;

    foreach my $list ($self->{th}->dump)
    {
	foreach my $item (@$list)
	{
	    delete $self->{data}{$item};
	}

	$self->SUPER::add($list);
    }
}

sub find
{
    my $self = shift;

    $self->{th}->find(@_);

}

sub delete
{
    my $self = shift;

    $self->{th}->delete(@_);
    $self->SUPER::delete(@_);
}

sub dump
{
    my $self = shift;

    $self->{th}->dump(@_);

}

sub _add_thing
{
    my $self = shift;
    my $list = shift;

    my @items = $self->_make_list($list);
    foreach (@items)
    {
	my $item = $self->{params}{ignore_case} ? lc $_ : $_; 

	my $tmp = $self->{data}{$item};
	$tmp = \@items;
	$self->{data}{$item} = $tmp;
    }
}

__END__

=head1 NAME

Thesaurus::DBM - Subclass of Thesaurus that ties data structure to DBM file.

=head1 SYNOPSIS

  use Thesaurus qw(DB_File Storable);

  my $book = Thesaurus->new( ignore_case => 1,
                             filename => $filename,
                             flags => $flags,
                             mode => $mode,
                             extra => \@more_params );

=head1 DESCRIPTION

This subclass of Thesaurus implements a tied interface to a DBM file
on disk, allowing persistence.

=head1 use Thesaurus::DBM (@params)

Thesaurus::DBM takes the same parameters as MLDBM.  The most important
are the first two, which are the DBM file module to use and the
serialization module to use.  See the MLDBM documentation for more
details.

=head1 METHODS

=over 4

=item * new( %params );

This method returns a new Thesaurus::DBM object tied to a DBM file as
defined by the parameters passed to this method.

This method takes the following parameters:

=item * ignore_case (0 or 1) - A boolean parameter.  If true, then the
object will be case insensitive.  It is _always_ case-preservative for
its data.

=item * filename ($) - The DBM filename.

=item * flags ($) - Flags passed to the appropriate DBM module.

=item * mode ($) - Mode passed to the appropriate DBM module.

=item * extra (\@) - Anything passed to this parameter will be passed
to the DBM module as an additional argument.

For the BerkeleyDB module, and others that don't follow the
AnyDBM_File module syntax, just put all the parameters in extra and
Thesaurus::DBM will handle this appropriately.

=back

All other methods are indentical to Thesaurus.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 SEE ALSO

Thesaurus, Thesaurus::File, Thesaurus::DBI, MLDBM, DB_File, GDBM_File,
SDBM_File, NDBM_File, ODBM_File

=head1 COPYRIGHT

Copyright (c) 1999 David Rolsky. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
