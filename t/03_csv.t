use strict;

use File::Spec;

use lib File::Spec->curdir, File::Spec->catdir( File::Spec->curdir, 't' );

use File::Temp;

use SharedTests;

use Test::More;

my (undef, $filename) = File::Temp::tempfile( undef, OPEN => 0 );

eval
{
    SharedTests::run_tests( class => 'Thesaurus::CSV',
                            extra_tests => 5,
                            p => { filename => $filename },
                          );

    {
        my $th = Thesaurus::CSV->new( filename => $filename );

        $th->add( [ qw( a b c ) ],
                  [ qw( 1 2 3 ) ],
                );

        eval { $th->save };

        ok( ! $@,
            "save method should not die" );
    }

    {
        my $th = Thesaurus::CSV->new( filename => $filename );

        my @words = sort $th->find('a');
        is( scalar @words, 3,
            "three matches should be returned" );

        my $x = 0;
        foreach ( qw( a b c ) )
        {
            is( $words[$x++], $_,
                "\$words[$x] should be $_" );
        }
    }
};

warn $@ if $@;

unlink $filename
    or warn "cannot unlink temporary file $filename: $!";
