#!/usr/bin/env perl
# genotype.pl
# Mike Covington
# created: 2011-12-05
#
# Description:
#
use strict;
use warnings;
use Getopt::Long;

use genotyping_commander;

my $usage = <<USAGE_END;

USAGE:
genotype.pl
  --id           Sample identifier
  --bam          Sample alignment file (.bam)
  --fasta        Reference file (.fasta/.fa)
  --out_dir      Output directory [current]
  --threads      Number of threads [1]
  --verbose
  --help

USAGE_END

my ( $id, $bam_file, $fasta_file, $out_dir, $threads, $verbose, $help );
my $options = GetOptions(
    "id=s"      => \$id,
    "bam=s"     => \$bam_file,
    "fasta=s"   => \$fasta_file,
    "out_dir=s" => \$out_dir,
    "threads=i" => \$threads,
    "verbose"   => \$verbose,
    "help"      => \$help,
);

die $usage unless $options;
die $usage if $help;
die $usage
  unless defined $id
  && defined $bam_file
  && defined $fasta_file;

my $geno = genotyping_commander->new(
    id      => $id,
    bam     => $bam_file,
    fasta   => $fasta_file,
    out_dir => $out_dir,
    threads => $threads,
    verbose => $verbose,
);

$geno->extract_mpileup;
$geno->genotype;

exit;