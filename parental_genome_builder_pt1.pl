#!/usr/bin/perl
# parental_genome_builder_pt1.pl
# Mike Covington
# created: 2012-01-03
#
# Description: 
#
use strict; use warnings;
use Getopt::Long;

my $chr_num;
my $m82_rna_snp_dir = "/Volumes/Runner_3B/Mike_temp_SolRAID/Mike_SNPs/M82_SNPS";
my $pen_rna_snp_dir = "/Volumes/Runner_3B/Mike_temp_SolRAID/Mike_SNPs/PENN_SNPS";
my $m82_rescan_snps = "/Volumes/Runner_3B/Mike_temp_SolRAID/Mike_SNPs/M82_RESCAN/M82vsHz_repeat_frequency_filtered_uniqueSNP.txt";
my $pen_rescan_snps = "/Volumes/Runner_3B/Mike_temp_SolRAID/Mike_SNPs/PENN_RESCAN/PENvsHz_repeat_frequency_filtered_uniqueSNP.txt";
my $cov_dir = "/Volumes/Runner_3B/Mike_temp_SolRAID/Mike_SNPs/coverage_out";
my $output_dir = "./";

GetOptions (
	"chr=i" => \$chr_num,    # numeric
	"msnp=s"   => \$m82_rna_snp_dir,      # string
	"psnp=s"   => \$pen_rna_snp_dir,      # string
	"mrescan=s"   => \$m82_rescan_snps,      # string
	"prescan=s"   => \$pen_rescan_snps,      # string
	"cov=s"   => \$cov_dir,      # string
	"out=s"	=>	\$output_dir
);

die "USAGE: parental_genome_builder_pt1.pl --chr <> --msnp <> --psnp <> --mrescan <> --prescan <> --cov <> --out <>\n" unless $chr_num >= 0;

my $chr_offset = $chr_num + 1;
my $chr_format;
if ($chr_num < 10) {
	$chr_format = "0$chr_num";
} else {
	$chr_format = $chr_num;
}


#OPEN SNP FILES
my $m82_rna_snps = $m82_rna_snp_dir . "/01.2.SNP_table.bwa_tophat_m82.sorted.dupl_rm.realigned.sorted.$chr_offset.$chr_offset.nogap.gap.FILTERED.csv";
my $pen_rna_snps = $pen_rna_snp_dir . "/01.2.SNP_table.bwa_tophat_penn.sorted.dupl_rm.realigned.sorted.$chr_offset.$chr_offset.nogap.gap.FILTERED.csv";
open (M82_RNA_SNPS, $m82_rna_snps) or die "Can't open $m82_rna_snps";
open (PEN_RNA_SNPS, $pen_rna_snps) or die "Can't open $pen_rna_snps";
open (M82_RE_SNPS, $m82_rescan_snps) or die "Can't open $m82_rescan_snps";
open (PEN_RE_SNPS, $pen_rescan_snps) or die "Can't open $pen_rescan_snps";

#OPEN COVERAGE FILES
my $m82_rna_cov_file = $cov_dir . "/m82.sl2.40ch$chr_format.coverage.col";
my $pen_rna_cov_file = $cov_dir . "/penn.sl2.40ch$chr_format.coverage.col";
my $m82_rescan_cov_file = $cov_dir . "/m82_rescan_no_repeats.SL2.40ch$chr_format.coverage.whit";
my $pen_rescan_cov_file = $cov_dir . "/penn_rescan_no_repeats.SL2.40ch$chr_format.coverage.whit";
open (M82_RNA_COV, $m82_rna_cov_file) or die "Can't open $m82_rna_cov_file";
open (PEN_RNA_COV, $pen_rna_cov_file) or die "Can't open $pen_rna_cov_file";
open (M82_RE_COV, $m82_rescan_cov_file) or die "Can't open $m82_rescan_cov_file";
open (PEN_RE_COV, $pen_rescan_cov_file) or die "Can't open $pen_rescan_cov_file";

#OPEN MASTER SNP FILE
`mkdir $output_dir`;
my $master_snp_file = ">$output_dir/master_snp_list.chr$chr_format";
open (MASTER, $master_snp_file) or die "Can't open $master_snp_file";
print MASTER join("\t", "chr", "pos", "ref_base", "snp_base", "genotype", "RESCANvsRNAseq");

#discard headers
<M82_RNA_SNPS>;
<PEN_RNA_SNPS>;

my $temp_line;

#read in first line of each SNP file; for RNAseq, need to skip if insertion/decimal in position (at least for now); for RESCAN SNPs, need to skip to correct chromosome and skip SNPs where ref_base eq "N"
my (@m82_rna_snp, @pen_rna_snp, @m82_rescan_snp, @pen_rescan_snp);
foreach my $line (<M82_RNA_SNPS>) {
	chomp $line;
	@m82_rna_snp = split(/,/, $line); # 0=chr, 1=pos, 2=ref_base , 8=snp_base
	last unless (split(/\./, $m82_rna_snp[1]))[1]; #keep unless there is a decimal in position (and is, therefore, an insertion)
}
foreach my $line (<PEN_RNA_SNPS>) {
	chomp $line;
	@pen_rna_snp = split(/,/, $line); # 0=chr, 1=pos, 2=ref_base , 8=snp_base
	last unless (split(/\./, $pen_rna_snp[1]))[1]; #keep unless there is a decimal in position (and is, therefore, an insertion)
}
foreach my $line (<M82_RE_SNPS>) {
	chomp $line;
	@m82_rescan_snp = split(/\t/, $line); # 0=chr, 1=pos, 2=ref_base , 3=snp_base
	last if $m82_rescan_snp[0] eq "SL2.40ch" . $chr_format;
}
while ($m82_rescan_snp[2] eq "N") {
	chomp($temp_line = <M82_RE_SNPS>);
	@m82_rescan_snp = split(/\t/, $temp_line);
}
foreach my $line (<PEN_RE_SNPS>) {
	chomp $line;
	@pen_rescan_snp = split(/\t/, $line);
	last if $pen_rescan_snp[0] eq "SL2.40ch" . $chr_format;
}
while ($pen_rescan_snp[2] eq "N") {
	chomp($temp_line = <PEN_RE_SNPS>);
	@pen_rescan_snp = split(/\t/, $temp_line);
}

#read in cov files until at correct chromosome
my (@m82_rna_cov, @pen_rna_cov, @m82_rescan_cov, @pen_rescan_cov);
foreach my $line (<M82_RNA_COV>) {
	chomp $line;
	@m82_rna_cov = split(/,/, $line); # 0=chr, 1=pos, 2=coverage
	chomp($temp_line = <PEN_RNA_COV>);
	@pen_rna_cov = split(/,/, $temp_line);
	chomp($temp_line = <M82_RE_COV>);
	@m82_rescan_cov = split(/,/, $temp_line);
	chomp($temp_line = <PEN_RE_COV>);
	@pen_rescan_cov = split(/,/, $temp_line);
	last if $m82_rna_cov[0] eq "SL2.40ch" . $chr_format;
}

#advance through coverage lines one at a time.  for each position, check against SNP positions.  if there is a match, confirm sufficient coverage in corresponding partner.  if sufficient coverage, confirm SNP and not indel.  If SNP, write to master SNP file (include chr, pos, ref_base, snp_base, genotype and RESCANvsRNAseq).  Advance SNP file that was used to next SNP position.  Make sure to allow for multiple SNPs at same position. (Can compare later)
until ($m82_rna_cov[0] ne "SL2.40ch" . $chr_format) { ##what about at EOF? Do I also need to check for defined/exists?
	my $pos = $m82_rna_cov[1];
	
	if ($m82_rna_snp[1] == $pos) {
		if ($pen_rna_cov[2] >=4 && $m82_rna_snp[8] ne "del") {
			print MASTER join("\t", @m82_rna_snp[0,1,2,8], "M82", "RNAseq");
		}
		foreach my $line (<M82_RNA_SNPS>) {
			chomp $line;
			@m82_rna_snp = split(/,/, $line); # 0=chr, 1=pos, 2=ref_base , 8=snp_base
			last unless (split(/\./, $m82_rna_snp[1]))[1]; #keep unless there is a decimal in position (and is, therefore, an insertion)
		}
	}
	
	if ($pen_rna_snp[1] == $pos) {
		if ($m82_rna_cov[2] >=4 && $pen_rna_snp[8] ne "del") {
			print MASTER join("\t", @pen_rna_snp[0,1,2,8], "PEN", "RNAseq");
		}
		foreach my $line (<PEN_RNA_SNPS>) {
			chomp $line;
			@pen_rna_snp = split(/,/, $line); # 0=chr, 1=pos, 2=ref_base , 8=snp_base
			last unless (split(/\./, $pen_rna_snp[1]))[1]; #keep unless there is a decimal in position (and is, therefore, an insertion)
		}
	}
	
	if ($m82_rescan_snp[1] == $pos) {
		if ($pen_rescan_cov[2] >=4) {
			print MASTER join("\t", @m82_rescan_snp, "M82", "RESCAN");
		}
		foreach my $line (<M82_RE_SNPS>) {
			chomp $line;
			@m82_rescan_snp = split(/,/, $line); # 0=chr, 1=pos, 2=ref_base , 8=snp_base
			last unless $m82_rescan_snp[2] eq "N"; #keep unless ref_base eq "N"
		}
	}
	
	if ($pen_rescan_snp[1] == $pos) {
		if ($m82_rescan_cov[2] >=4) {
			print MASTER join("\t", @pen_rescan_snp, "PEN", "RESCAN");
		}
		foreach my $line (<PEN_RE_SNPS>) {
			chomp $line;
			@pen_rescan_snp = split(/,/, $line); # 0=chr, 1=pos, 2=ref_base , 8=snp_base
			last unless $pen_rescan_snp[2] eq "N"; #keep unless ref_base eq "N"
		}
	}

	chomp($temp_line = <M82_RNA_COV>);	
	@m82_rna_cov = split(/,/, $temp_line); # 0=chr, 1=pos, 2=coverage
	chomp($temp_line = <PEN_RNA_COV>);	
	@pen_rna_cov = split(/,/, $temp_line);
	chomp($temp_line = <M82_RE_COV>);	
	@m82_rescan_cov = split(/,/, $temp_line);
	chomp($temp_line = <PEN_RE_COV>);	
	@pen_rescan_cov = split(/,/, $temp_line);
}

# close (M82_RNA_SNPS, PEN_RNA_SNPS, M82_RE_SNPS, PEN_RE_SNPS, M82_RNA_COV, PEN_RNA_COV, M82_RE_COV, PEN_RE_COV);
close (M82_RNA_SNPS);
close (PEN_RNA_SNPS);
close (M82_RE_SNPS);
close (PEN_RE_SNPS);
close (M82_RNA_COV);
close (PEN_RNA_COV);
close (M82_RE_COV);
close (PEN_RE_COV);
close (MASTER);
exit;
## incorporate actual writing of parental genomes in until loop?  NO, I think having a separate script would be better.  Easier to filter out SNPs in common between m82 and pen.  also easier to filter out disagreements between RNAseq and RESCAN