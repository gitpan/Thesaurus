use Cwd;
use File::Spec;

unless (eval { require Module::Build::Compat; 1 }) {
    require ExtUtils::MakeMaker;

    print "This module required Module::Build to install itself.\n";

    my $yn = ExtUtils::MakeMaker::prompt( '  Install Module::Build', 'y' );

    if ($yn =~ /^y(es)?/i) {
        # save this cause CPAN will chdir all over the place.
        my $cwd = cwd();
        my $makefile = File::Spec->rel2abs($0);

        require CPAN;
        CPAN->install('Module::Build');

        chdir $cwd
            or die "Cannot chdir to $cwd: $!";

        exec( $^X, $makefile, @ARGV )
    } else {
        warn "Cannot install Thesaurus without Module::Build.  Exiting ...\n";
        exit 0;
    }
}

require Module::Build::Compat;
Module::Build::Compat->run_build_pl( args => \@args );
Module::Build::Compat->write_makefile;
