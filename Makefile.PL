use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Thesaurus',
	      'VERSION_FROM' => 'Thesaurus.pm', # finds $VERSION
	      'PM' =>
	      { 'Thesaurus.pm' => '$(INST_LIBDIR)/Thesaurus.pm',
		'File.pm' =>  '$(INST_LIBDIR)/Thesaurus/File.pm',
		'DBM.pm' =>  '$(INST_LIBDIR)/Thesaurus/DBM.pm',
		'DBI.pm' =>  '$(INST_LIBDIR)/Thesaurus/DBI.pm',
	      },
);
