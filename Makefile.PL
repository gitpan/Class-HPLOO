###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Class::HPLOO',
    'VERSION_FROM' => 'HPLOO.pm',
    'PREREQ_PM'    => {
                       'Filter::Simple'  => 0.02 ,
                       'Filter::Util::Call' => 1.06 ,
                       'Text::Balanced' => 1.89 ,
                      } ,
    'EXE_FILES'     => [ qw(script/build-hploo.pl) ],
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'HPLOO.pm',
        AUTHOR        => 'Graciliano M. P. <gm@virtuasites.com.br>'
       ) : ()
     ),
);

1;


