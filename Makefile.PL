use strict;
use warnings;
use ExtUtils::MakeMaker;

my %prq = (
         Encode     => 0,
        'List::Util' => 0,
         Memoize      => 0,
        'Scalar::Util' => 0,
        'Test::More'   => 0,
    );

eval { require Hash::Util::FieldHash } or $prq{'Tie::RefHash::Weak'} = 0;

WriteMakefile(
    NAME                => 'JE',
    AUTHOR              => 'Father Chrysostomos <sprout @ cpan . org>',
    VERSION_FROM        => 'lib/JE.pm',
    ABSTRACT_FROM       => 'lib/JE.pm',
    PL_FILES            => {},
    PREREQ_PM           => \%prq,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JE-*' },
);
