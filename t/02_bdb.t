use strict;

use File::Spec;

use lib File::Spec->curdir, File::Spec->catdir( File::Spec->curdir, 't' );

use File::Temp;

use SharedTests;

my (undef, $filename) = File::Temp::tempfile( undef, OPEN => 0 );

eval
{
    SharedTests::run_tests( class => 'Thesaurus::BerkeleyDB',
                            p => { filename => $filename,
                                   locking => 1,
                                 },
                          );
};

warn $@ if $@;

unlink $filename
    or warn "cannot unlink temporary file $filename: $!";
