#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use open qw(:std :utf8);

my @results;

foreach my $arg (@ARGV) {
  foreach my $file (glob "$arg/src/*.o[0-9]*") {
    open (my $f, "<", $file) or die "Cannot open file $file: $!";
    my ($type, $suptype, $span) = ("", "", "");
    while (<$f>) {
      m#^Type:\s+[0-9.]+\s+/\s+[0-9.]+\s+/\s+([0-9.]+)# and $type = $1;
      m#^Suptype:\s+[0-9.]+\s+/\s+[0-9.]+\s+/\s+([0-9.]+)# and $suptype = " $1";
      m#^Span:\s+[0-9.]+\s+/\s+[0-9.]+\s+/\s+([0-9.]+)# and $span = " $1";

      m#^accuracy:\s+.*FB1:\s+([0-9.]+)\s*$# and $type = $1;
    }
    close $f;
    length($type) and push @results, {score=>$type, file=>$file, value=>"$type$suptype"};
  }
}

my @rows = (
  ["forms + WE", "[_-]forms_we-"],
  ["forms + CLE", "[_-]forms_cle\\d+-"],
  ["forms + WE + 2CH", "[_-]forms_we\\+2ch-"],
  ["forms + WE + CLE", "[_-]forms_we\\+cle\\d+-"],
  ["forms + WE + CLE + 2CH", "[_-]forms_we\\+2ch\\+cle\\d+-"],
  ["forms + WE + CLE + 2CH + CF", "[_-]forms_we\\+2ch\\+cf\\+cle\\d+-"],
  ["f\\_l\\_t + WE", "[_-]flt_we-"],
  ["f\\_l\\_t + CLE", "[_-]flt_cle\\d+-"],
  ["f\\_l\\_t + WE + 2CH", "[_-]flt_we\\+2ch-"],
  ["f\\_l\\_t + WE + CLE", "[_-]flt_we\\+cle\\d+-"],
  ["f\\_l\\_t + WE + CLE + 2CH", "[_-]flt_we\\+2ch\\+cle\\d+-"],
  ["f\\_l\\_t + WE + CLE + 2CH + CF", "[_-]flt_we\\+2ch\\+cf\\+cle\\d+-"],
);

my @cols = (
  ["CNEC 1.0", "-cs-cnec1.0-etest-f"],
#  ["-dtest", "-cs-cnec1.0-etest-nodtest"],
#  ["CNEC 1.1", "-cs-cnec1.1-etest-f"],
  ["CNEC 2.0", "-cs-cnec2.0-etest-f"],
  ["Konkol 1.1", "-cs-cnec1.1_konkol-etest"],
  ["Konkol 2.0", "-cs-cnec2.0_konkol-etest"],
  ["English", "-en-conll2003_en-etest"],
);

my $col_desc = join("|", "", "l", ("r") x @cols, "");

print <<EOF;
\\begin{table}
  \\begin{center}
    \\begin{tabular}{$col_desc}
    \\hline
EOF
print "    \\multicolumn{1}{|c|}{Method} & " . (join " & ", map {"\\multicolumn{1}{c|}{$_->[0]}"} @cols) . " \\\\ \\hline\n";
foreach my $row (@rows) {
  print "    $row->[0]";
  foreach my $col (@cols) {
    my $value = "";
    foreach my $result (@results) {
      if ($result->{file} =~ /$row->[1]/ && $result->{file} =~ /$col->[1]/) {
        if ($value) {
          $value = "[$value : $result->{value}]";
        } else {
          $value = $result->{value};
        }
      }
    }
    print " & $value";
  }

  print " \\\\ \\hline\n";
}
print <<EOF;
    \\end{tabular}
  \\end{center}
  \\caption{Automatically generated table with NER results.}
\\end{table}
EOF
