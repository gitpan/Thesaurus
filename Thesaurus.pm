package Thesaurus;

use strict;
use vars qw[$VERSION];
use Carp;

$VERSION = (sprintf '%2d.%02d', q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/) - 1;

1;


sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $self = { params => \%params,
		 data => {} };

    return bless $self, $class;
}

sub add
{
    my $self = shift;

    foreach my $list (@_)
    {
	$self->_add_thing($list);
    }
}

sub _add_thing
{
    my $self = shift;
    my $list = shift;

    my @items = $self->_make_list($list);
    foreach (@items)
    {
	my $item = $self->{params}{ignore_case} ? lc $_ : $_; 

	$self->{data}{$item} = \@items;
    }
}

sub _make_list
{
    my $self = shift;
    my $list = shift;

    my @items;
    foreach (@$list)
    {
	my $item = $self->{params}{ignore_case} ? lc $_ : $_; 

	if (exists $self->{data}{$item})
	{
	    push @items, @{ $self->{data}{$item} };
	    last;
	}
    }

    @items = keys %{ { map {$_ => 1} @items, @$list } };

    return @items;
}

sub delete
{
    my $self = shift;

    foreach (@_)
    {
	my $item = $self->{params}{ignore_case} ? lc $_ : $_;
	next unless exists $self->{data}{$item};

	foreach my $key ( @{ $self->{data}{$item} } )
	{
	    delete $self->{data}{$key};
	}
    }
}

sub find
{
    my $self = shift;

    if (@_ > 1)
    {
	my %lists;
	foreach my $key (@_)
	{
	    $key = lc $key if $self->{params}{ignore_case};

	    # Anonymize to keep people away from our lists!
	    $lists{$key} = exists $self->{data}{$key} ? [ @{ $self->{data}{$key} } ] : undef;
	}

	return %lists if keys %lists;
    }
    else
    {
	my $key = $self->{params}{ignore_case} ? lc $_[0] : $_[0];

	return @{ $self->{data}{$key} } if exists $self->{data}{$key};
    }

    return;
}

sub dump
{
    my $self = shift;

    my (%done, @data);
    foreach my $key (keys %{ $self->{data} })
    {
	next if $done{$key};

	map {$done{$_} = 1} @{ $self->{data}{$key} };
	push @data, $self->{data}{$key};
    }

    return @data
}


__END__

=head1 NAME

Thesaurus - David Rolsky (grimes@waste.org)

=head1 SYNOPSIS

 use Thesaurus;

 $th = new Thesaurus( -files => ['file1', 'file2'],
		      -ignore_case => 1 );

 @words = $th->find('vegan');

 %words = $th->find('animal', 'liberation');

 foreach $word ( @{ $words{animal} } )
 {
     #something ...
 }

 $th->add_file('file1', 'file2');

 $th->add('tofu', 'alternative methodologies');

 $th->delete('meat', 'vivisection');

=head1 DESCRIPTION

Thesaurus is a module that allows you to create lists of related
things.  It was created in order to facilitate searches of a database
of Chinese names in Anglicized form.  Because there are various
schemes to create phonetic representations of Chinese words, the
following can all represent the same Chinese character:

 Woo
 Wu
 Ng

Thesaurus can be used for anything that fits into a scalar by using
the C<new> method with no parameters and then calling the C<add>
method to add data.

Thesaurus also acts as the parent class to several child classes which
implement various forms of persistence for the data structure.  This
module can be used on its own to instantiate an object that lives for
the life of its scope.

=head1 METHODS

=over 4

=item * new(%params)

 $th = Thesaurus->new(%params);

The C<new> method returns a Thesaurus object.

Parameters:

=item * ignore_case (0 or 1) - A boolean parameter.  If true, then the
object will be case insensitive.  It is _always_ case-preservative for
its data.

=item * find(@items);

 @words = $th->find('Big Hat');
 %words = %th->find('Big Hat', 'Faye Wong');

The C<find> method returns either a list or a hash, depending on
context.  Given a single word to find, it returns the list of words
that it is associated with, including the word that was given.  If no
matches  are found then it returns an empty list.

If it is given multiple words, it returns a hash.  The keys of the has
are the words given, and the keys are list references containing the
associated words.  If no words were found then the key has a value of
0.  If none of the words match then an empty list is returned.

=item * add(\@list1, \@list2)

 $th->add(\@related1, \@related2);

The C<add> method takes a list of list references.  Each of these
references should contain a set of associated scalars.  Like the add
files method, if an entry in the files matches an entry already
in the object, then it is appended to the existing list, otherwise a
new entry is created.

=item * delete(@items)

 $th->delete($element);

The C<delete> method takes a list of items to delete.  All the
associations for the given items will be removed.

=item * dump

 @list_refs = $th->dump;

Returns a list of list references.  Each one of these list references
contains one set of associations.  Each association list is returned
once (not once per item).

=back

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 SEE ALSO

Thesaurus::File, Thesaurus::DBM, Thesaurus::DBI

=head1 COPYRIGHT

Copyright (c) 1999 David Rolsky. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
