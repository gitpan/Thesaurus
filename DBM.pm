package Thesaurus::DBM;

use strict;
use vars qw[$VERSION @ISA];

use Thesaurus;
use File::Flock;
use Carp;

$VERSION = (sprintf '%2d.%02d', q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/) - 1;
@ISA = qw(Thesaurus);

1;

# use MLDBM with appropriate parameters.
sub import
{
    shift;

    die "Can't use SDBM_File with Thesaurus::DBM (see docs)\n"
	if ( (not $_[0]) || ($_[0] eq 'SDBM_File') );

    die "Can't use NDBM_File with Thesaurus::DBM (see docs)\n"
	if $_[0] eq 'NDBM_File';

    die "can't use ODBM_File with Thesaurus::DBM (see docs)\n"
	if $_[0] eq 'ODBM_File';

    my $ev_string = 'use MLDBM ';

    $ev_string .= 'qw(';
    $ev_string .= join ' ', @_;
    $ev_string .= ');';

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

    # This is designed to support both the standard AnyDBM_File syntax
    # and the BerkeleyDB module syntax.
    my @params;
    push @params, $self->{params}{filename} if defined $self->{params}{filename};
    push @params, $self->{params}{flags} if defined $self->{params}{flags};
    push @params, $self->{params}{mode} if defined $self->{params}{mode};
    push @params, @{ $self->{params}{extra} };

    $self->{params}{locking} = 1 unless defined $self->{params}{locking};
    $self->{params}{lock_wait} = 2 unless defined $self->{params}{lock_wait};

    my %hash;
    my $tied_obj = tie %hash, 'MLDBM', @params;
    croak ("can't tie hash to MLDBM: $!") unless $tied_obj;

    $self->{data} = \%hash;
    $self->{tied_obj} = $tied_obj;

    return $self;
}

sub add
{
    my $self = shift;

    # Exclusive lock
    $self->_lock(undef)
	if $self->{params}{locking};

    my @add;
    foreach my $list (@_)
    {
	my @new_list = @$list;

	foreach my $new_item (@$list)
	{
	    push @new_list, @{ $self->{data}{$new_item} }
		if exists $self->{data}{$new_item};
	}

	foreach my $item (@new_list)
	{
	    delete $self->{data}{$item};
	}

	push @add, \@new_list;
    }

    $self->SUPER::add(@add);

    $self->_unlock
	if $self->{params}{locking};
}

sub find
{
    my $self = shift;

    $self->_lock('shared');

    my @ret = $self->SUPER::find(@_);

    $self->_unlock;

    return @ret;
}

sub delete
{
    my $self = shift;

    # Exclusive lock
    $self->_lock(undef);

    $self->SUPER::delete(@_);

    $self->_unlock;
}

sub dump
{
    my $self = shift;

    $self->SUPER::dump(@_);
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

sub _lock
{
    my $self = shift;
    my $type = shift;

    unless ( lock($self->{params}{filename}, $type, 'nonblocking') )
    {
	my $x = 0;
	my $locked = 0;
	while (not $locked and $x++ < $self->{params}{lock_wait})
	{
	    lock($self->{params}{filename}, $type, 'nonblocking')
		and $locked = 1;
	}

	die "can't get lock on $self->{params}{filename}: $!"
	    unless $locked;
    }
}

sub _unlock
{
    my $self = shift;

    die "can't unlock $self->{params}{filename}: $!" unless unlock($self->{params}{filename});
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

Thesaurus::DBM will not work with SDBM_File, NDBM_File, or ODBM_File
because they doe not support C<exists> on tied hashes.  I believe that
this is fixed in Perl 5.6 (at least for SDBM_File).

Thesaurus::DBM now supports locking.  When locking is enabled all
operations are atomic.

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

=item * locking ($) - A true or false value indicating whether or not
you wish the object to attempt to get a lock for reading and writing
to the DBM file.  Locking is safer but slower.  The default is to
enable locking.

=item * lock_wait ($) - How long, in seconds, to wait for a lock.  The
default is 2 seconds.

=back

All other methods are indentical to Thesaurus.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 SEE ALSO

Thesaurus, Thesaurus::File, Thesaurus::DBI, MLDBM, DB_File, GDBM_File

=head1 COPYRIGHT

Copyright (c) 1999 David Rolsky. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
