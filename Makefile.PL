use strict;
use ExtUtils::MakeMaker;

WriteMakefile
(
 NAME            => 'RRD::Threshold',
 DISTNAME        => 'rrdpoller',
 VERSION_FROM    => 'rrdpoller',
 PERL_ARCHLIB    => undef,
 PREREQ_PM       =>
 {
  Error => '0.15',
  RRDs  => '1.000481',
 },
 AUTHOR          => 'Olivier Poitrey <rs@mmania.com>',
);
