use strict;
use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.9 2004/12/07 12:36:21 rs Exp $

WriteMakefile
(
 NAME            => 'rrdpoller',
 DISTNAME        => 'rrdpoller',
 VERSION_FROM    => 'rrdpoller',
 PERL_ARCHLIB    => undef,
 PM              => 
 {
  'Threshold.pm' => '$(INST_LIB)/RRD/Threshold.pm',
  'Query.pm'     => '$(INST_LIB)/RRD/Query.pm',
 },
 EXE_FILES       => [qw(rrdpoller)],
 PREREQ_PM       =>
 {
  'Error'        => '0.15',
  'RRDs'         => '1.000481',
  'File::Temp'   => '',
 },
 AUTHOR          => 'Olivier Poitrey <rs@mmania.com>',
 dist            =>
 {
  DIST_DEFAULT   => 'README all checkout metafile sign tardist checkin',
  COMPRESS       => 'gzip -9f',
 }
);

# if we make sign first and make dist then, then any change to
# META.yml will ruin the signature

# if we make dist first and make sign then, then the correct signature
# will not be part of the tarball

# So we must alter make dist to first write META.yml, then let us
# sign, then do the tarball.

sub MY::postamble {
q{
README: rrdpoller Makefile
	chmod +w $@
	pod2text rrdpoller > $@

checkout ::
	cvs up META.yml SIGNATURE README

checkin ::
	cvs ci -m 'new release' META.yml SIGNATURE README

sign ::
	cpansign -s

}
}
