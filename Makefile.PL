use strict;
use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.13 2004/12/08 01:11:24 rs Exp $

if(!eval {require RRDs; 1})
{
    $| = 1;
    print <<EOT;
The RRDs perl library seems not installed on your system. This module
can't work without this library. You can download this library on the
following URL: http://rrdtool.cs.pu.edu.tw/download.html. If you install
this module anyway, it won't be usable until the RRDs library won't be
installed. Do you want to install this module anyway [Y/n]:
EOT
    my $answer = <>;
    chomp($answer);
    if($answer =~ /^n/i)
    {
        exit 1;
    }
}

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
  DIST_DEFAULT   => 'README all changelog checkout metafile sign tardist checkin',
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

changelog ::
	@test $(shell head -1 debian/changelog|perl -pe 's/.*\(|\).*//g') == $(VERSION) || \
  (echo "Versions mismatch between changelog and script"; false)
	cvs tag V$(subst .,_,$(VERSION))
	@echo "Tagging CVS"
	@! cvs -q tag V$(subst .,_,$(VERSION))|grep -q ^W || \
  (echo "Some files are already tagged with this version"; false)
	# TODO: generate a changelog


checkout ::
	cvs up META.yml SIGNATURE README

checkin ::
	cvs ci -m 'new release' META.yml SIGNATURE README

sign ::
	cpansign -s

}
}
