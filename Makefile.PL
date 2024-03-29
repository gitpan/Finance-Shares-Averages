use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Finance::Shares::Averages',
    'VERSION_FROM'	=> 'Averages.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Finance::Shares::Sample => 0.02,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Averages.pm', # retrieve abstract from module
       AUTHOR     => 'Chris Willmot <chris@willmot.co.uk>') : ()),
);
