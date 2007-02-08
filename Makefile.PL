use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JE',
    AUTHOR              => 'Father Chrysostomos <sprout @ cpan . org>',
    VERSION_FROM        => 'lib/JE.pm',
    ABSTRACT_FROM       => 'lib/JE.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'List::Util' => 0,
        'Scalar::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JE-*' },
);
