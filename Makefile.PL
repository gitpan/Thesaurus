use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Thesaurus',
	      'VERSION' => '0.15',
	      'PM' =>
	      { 'Thesaurus.pm' => '$(INST_LIBDIR)/Thesaurus.pm',
		'Thesaurus/File.pm' =>  '$(INST_LIBDIR)/Thesaurus/File.pm',
		'Thesaurus/DBM.pm' =>  '$(INST_LIBDIR)/Thesaurus/DBM.pm',
		'Thesaurus/DBI.pm' =>  '$(INST_LIBDIR)/Thesaurus/DBI.pm',
	      },
);
