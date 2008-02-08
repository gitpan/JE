BEGIN {
	require 5.006;
	$] == 5.009005 and require 5.01;
	# I’m getting tired of failure reports that are due to the buggi-
	# ness of 5.9.5.
}

use strict;
use ExtUtils::MakeMaker;

my %prq = (
#        'Date::Parse' => 0, # I will need this later
         Encode     => 2.02,
# perl 5.8.5 comes with Encode 2.01 and ‘decode_utf8 "\xef\xbb", FB_CROAK’
# fails to croak. 5.8.6,  which comes with 2.08 is fine.  But 2.12 is the
# earliest version available from CPAN  (or backpan),  so  I  can’t  test
# whether 5.8.5 works with 2.08 (I assume it does). In order to avoid forc-
# ing 5.8.6 users from upgrading, I’m putting 2.02 as the required version.
         Exporter   => 5.57,
        'List::Util' => 0,
         Memoize      => 0,
         re           => 0, # version???
        'Scalar::Util' => 1.1, # looks_like_number
         strict => 0,
        'Time::Local' => 0,
        'Time::Zone' => 0,
         warnings => 0,
 # for tests only:
        'Test::More'   => 0,
         utf8   => 0,
    );

eval { require Hash::Util::FieldHash } or $prq{'Tie::RefHash::Weak'} = 0;

WriteMakefile(
    NAME                => 'JE',
    AUTHOR              => 'Father Chrysostomos <sprout @ cpan . org>',
    VERSION_FROM        => 'lib/JE.pm',
    ABSTRACT_FROM       => 'lib/JE.pm',
    PL_FILES            => {},
    PREREQ_PM           => \%prq,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             TAR => 'COPYFILE_DISABLE=1 tar' },
    clean               => { FILES => 'JE-*' },
);
