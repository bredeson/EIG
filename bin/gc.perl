#!/usr/bin/env perl

sub usage {
    my $message = "@_";
    die "
Usage: gc.perl infile outfile

Required Arguments:
  infile  : input file of chisq statistics produced by eigenstrat
            program. It contains both uncorrected and EIGENSTRAT 
            statistics for each SNP.
  outfile : output file. It lists lambda inflation values (for 
            both uncorrected and EIGENSTRAT) chisq statistics 
            after scaling by lambda (uncorrected and EIGENSTRAT)

Computation of lambda is as described in Devlin and Roeder 1999.
A lambda above 1 indicates inflation in chisq statistics.
By definition, lambda is not allowed to be less than 1.

Running time of the gc.perl program is very fast.
    
$message

"
}

unless(@ARGV == 2) {usage("OOPS unexpected number of arguments")}

$P = $ARGV[0];
$out = $ARGV[1];

# get data
$m=0;
open(P,"$P") || die("Cannot open file: $P");
while($line = <P>) { if($line =~ /Chisq/) { last; } } # header lines
while($line = <P>)
{
  chomp($line);
  if($line =~ /NA/) 
  {
    $chisq1[$m] = -100;
    $chisq2[$m] = -100;
    $m++;  
    next;
  }
  my @array = split(/[\t ]+/,$line);
  $chisq1[$m] = $array[0]; # Chisq
  $chisq2[$m] = $array[1]; # EIGENSTRAT
  $m++; 
  $mvalid++;
}
close(P);
$nSNP = $m;
$nSNPvalid = $mvalid;

# compute $lambda1 (Chisq)
$CHISQTHRESH = 0.456;
$step = 0.25;
$oktoreducestep = 0;
for($iter=0; $iter<20; $iter++)
{
  $mm = 0;
  for($m=0; $m<$nSNP; $m++) 
  { 
    if($chisq1[$m] > $CHISQTHRESH) { $mm++; } 
  }
  $frac = $mm/$nSNPvalid; # frac of SNPs exceeding CHISQTHRESH
  if($frac > 0.5) { $CHISQTHRESH += $step; }
  else { $CHISQTHRESH -= $step; $oktoreducestep = 1; }
  if($oktoreducestep) { $step *= 0.5; }
}
$lambda1 = $CHISQTHRESH/0.456; # 0.456 is median if no inflation
if($lambda1 < 1) { $lambda1 = 1; } # not allowed to be less than 1

# compute $lambda2 (EIGENSTRAT)
$CHISQTHRESH = 0.456;
$step = 0.25;
$oktoreducestep = 1;
for($iter=0; $iter<20; $iter++)
{
  $mm = 0;
  for($m=0; $m<$nSNP; $m++) 
  { 
    if($chisq2[$m] > $CHISQTHRESH) { $mm++; } 
  }
  $frac = $mm/$nSNPvalid; # frac of SNPs exceeding CHISQTHRESH
  if($frac > 0.5) { $CHISQTHRESH += $step; }
  else { $CHISQTHRESH -= $step; $oktoreducestep = 1; }
  if($oktoreducestep) { $step *= 0.5; }
}
$lambda2 = $CHISQTHRESH/0.456; # 0.456 is median if no inflation
if($lambda2 < 1) { $lambda2 = 1; } # not allowed to be less than 1

# output
open(OUT,">$out") || die("Cannot open file: $out");
print OUT ("Chisq EIGENSTRAT\n");
printf OUT ("lambda=%.03f lambda=%.03f\n",$lambda1,$lambda2);
for($m=0; $m<$nSNP; $m++)
{
  if($chisq1[$m] < 0) { print OUT ("NA NA\n"); next; }
  printf OUT ("%.04f %.04f\n",$chisq1[$m]/$lambda1,$chisq2[$m]/$lambda2);
}
