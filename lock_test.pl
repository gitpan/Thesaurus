#!/usr/bin/perl

use File::Flock;

my $file = $ARGV[0] or die "no file given as argument\n";
my $type = $ARGV[1] eq 'shared' ? 'shared' : undef;

print lock ($file, $type, 'nonblocking');
