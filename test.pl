# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN
{
    $| = 1;

    eval 'use File::Flock;';

    if ($@)
    {
	warn "Couldn't load File::Flock, will skip Thesaurus::DBM tests.\n";
    }
    else
    {
	foreach my $mod ( qw[ DB_File GDBM_File ] )
	{
	    eval "use $mod";
	    unless ($@)
	    {
		$dbm_module = $mod;
		last;
	    }
	}

	eval "use MLDBM;";

	if ($@)
	{
	    warn "Couldn't load MLDBM, will skip Thesaurus::DBM tests.\n";
	}
	elsif (not defined $dbm_module)
	{
	    warn "Couldn't load DB_File or GDBM_File, will skip Thesaurus::DBM tests.\n";
	}
	else
	{
	    eval "use Thesaurus::DBM ($dbm_module)";
	}
    }

    eval "use Text::CSV_XS;";

    if ($@)
    {
	warn "Couldn't load Text::CSV_XS, will skip Thesaurus::File tests.\n";
    }
    else
    {
	eval 'use Thesaurus::File;';
    }

    print "1..1\n";
}
END {print "not ok 1\n" unless $loaded;}

use Thesaurus;
use Thesaurus::DBI;

$loaded = 1;
&result($loaded, 'Error compiling one of the modules');

use strict;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

warn "\nThesaurus\n\n";
my $th = Thesaurus->new;

# 1-8: Test add, find, and delete as well as case sensitivity.
{
    $th->add( [ qw{ a b c d E f } ],
	      [ qw{ 1 2 3 HELLO hello } ] );

    my @words = sort $th->find('a');

    &result( ( scalar @words == 6 ) &&
	     ( $words[1] eq 'a' && $words[2] eq 'b' && $words[3] eq 'c' &&
	       $words[4] eq 'd' && $words[0] eq 'E' && $words[5] eq 'f' ),
	     "Expected to receive (E a b c d f) from find but got (", (join ' ', @words), ")\n" );

    &result( $th->find('A'),
	     "Thesaurus object appears to be case insensitive when it should not be.\n" );

    $th->delete('E');
    &result( $th->find('a'),
	     "Delete did not remove all the related items.\n" );

    $th = Thesaurus->new( ignore_case => 1 );
    $th->add( [ qw{ a b c d E f } ],
	      [ qw{ 1 2 3 HELLO hello } ] );

    &result( scalar $th->find('e') == 6,
	     "Case insensitive object appears to be case sensitive.\n" );
    &result( scalar $th->find('E') == 6,
	     "Case insensitive object appears to be case sensitive.\n" );

    $th->add( ['e', 'q'], [7, 8] );

    &result( scalar $th->dump == 3,
	     "Adding multiple lists at once didn't work.\n" );
    &result( scalar $th->find('e') == 8,
	     "Adding to an existing list didn't work.\n");
}

my $tmpdir = '/tmp' if -w '/tmp';
$tmpdir ||= '/temp' if -w '/temp';
$tmpdir ||= '.' if -w '.';

unless (defined $tmpdir)
{
    warn( "Couldn't find a place to put temporary files to test Thesaurus::File and Thesaurus::DBM." .
	  "  Skipping remaining tests.\n" );
    exit;
}

goto DBM_TESTS unless $Thesaurus::File::VERSION;

warn "\nThesaurus::File\n\n";

# Make some files for Thesaurus::File tests.
open OUT, ">$tmpdir/th_file_$$.csv"
    or die "can't write to $tmpdir/th_file_$$.csv: $!";

print OUT << 'EOF';
a,b,c,d,E,f
1,2,3,HELLO,hello
EOF

close OUT;

open OUT, ">$tmpdir/th_file_${$}_2.csv"
    or die "can't write to $tmpdir/th_file_${$}_2.csv: $!";

print OUT << 'EOF';
sexxy,"12 Rods",bubba
7,8,9
EOF

close OUT;

my $th = Thesaurus::File->new( files => "$tmpdir/th_file_$$.csv" );

# 9-14: Test object creation, add_files method, and save method.
{
    my @words = sort $th->find('a');

    &result( ( scalar @words == 6 ) &&
	     ( $words[1] eq 'a' && $words[2] eq 'b' && $words[3] eq 'c' &&
	       $words[4] eq 'd' && $words[0] eq 'E' && $words[5] eq 'f' ),
	     "Expected to receive (E a b c d f) from find but got (", (join ' ', @words), ")\n" );

    $th->add_files("$tmpdir/th_file_${$}_2.csv");

    &result( scalar $th->dump == 4,
	     "Adding a new file doesn't seem to have worked.\n");
    &result( scalar $th->find(7) == 3,
	     "Adding a new file doesn't seem to have worked.\n");

    $th->save( filename => "$tmpdir/th_file_${$}_save.csv",
	       mode => 'write' );

    &result( -s "$tmpdir/th_file_${$}_save.csv",
	     "Saving object to disk didn't work." );

    undef $th;

    $th = Thesaurus::File->new( files => "$tmpdir/th_file_${$}_save.csv" );
    &result( scalar $th->dump == 4,
	     "Something was saved to disk by save method but it's not the right data.\n");
    &result( scalar $th->find(7) == 3,
	     "Something was saved to disk by save method but it's not the right data.\n");
}

unlink "$tmpdir/th_file_$$.csv"
    or die "can't remove $tmpdir/th_file_$$.csv: $!";
unlink "$tmpdir/th_file_${$}_2.csv"
    or die "can't remove $tmpdir/th_file_${$}_2.csv: $!";
unlink "$tmpdir/th_file_${$}_save.csv"
    or die "can't remove $tmpdir/th_file_${$}_save.csv: $!";

DBM_TESTS:

exit unless $Thesaurus::DBM::VERSION;

warn "\nThesaurus::DBM\n\n";
use Fcntl; # For flags

my $dbmfile = "$tmpdir/th_dbm_$$.dbm";
$th = Thesaurus::DBM->new( filename => $dbmfile,
			   flags => O_RDWR | O_CREAT,
			   mode => 0664 );

# 15-18: Basic functionality test for Thesaurus::DBM.
{
    $th->add( [ qw{ a b c d E f } ],
	      [ qw{ 1 2 3 HELLO hello } ] );

    my @words = sort $th->find('a');

    &result( ( scalar @words == 6 ) &&
	     ( $words[1] eq 'a' && $words[2] eq 'b' && $words[3] eq 'c' &&
	       $words[4] eq 'd' && $words[0] eq 'E' && $words[5] eq 'f' ),
	     "Expected to receive (E a b c d f) from find but got (", (join ' ', @words), ")\n" );

    $th->delete('E');
    &result( $th->find('a'),
	     "Delete did not remove all the related items.\n" );

    $th->add( [ qw{ a b c d E f } ] );

    $th->add( ['E', 'q'], [7, 8] );

    &result( scalar $th->dump == 3,
	     "Adding multiple lists at once didn't work.\n" );
    &result( scalar $th->find('E') == 7,
	     "Adding to an existing list didn't work.\n");
}

# 19-21: Locking tests.  Tests the equivalent functionality used
# internally in Thesaurus::DBM.
{
    open (TMP, ">$tmpdir/th_lock")
	or die "can't write to $tmpdir/th_lock: $!";

    print TMP 'lock test';

    close TMP;

    # Exclusive lock.
    lock("$tmpdir/th_lock", undef, 'nonblocking');

    &result( `perl lock_test.pl '$tmpdir/th_lock'` == 0,
	     "Couldn't get lock using File::Flock functions.\n" );

    unlock("$tmpdir/th_lock");

    lock ("$tmpdir/th_lock", 'shared', 'nonblocking');

    &result( `perl lock_test.pl '$tmpdir/th_lock' shared` == 1,
	     "Shared lock didn't work.\n" );

    &result( `perl lock_test.pl '$tmpdir/th_lock' exclusive` == 0,
	     "Was able to get exclusive lock when shared lock was supposedly already in place.\n" );

    unlock ("$tmpdir/th_lock");

    unlink "$tmpdir/th_lock"
	or die "can't remove $tmpdir/th_lock: $!";
}

unlink $dbmfile
    or die "can't remove $dbmfile: $!";



sub result
{
    my $ok = !!shift;
    use vars qw($TESTNUM);
    $TESTNUM++;
    print "not "x!$ok, "ok $TESTNUM\n";
    print @_ if !$ok;
}
