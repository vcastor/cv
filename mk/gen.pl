#!/usr/bin/perl
# mk/gen.pl — build plain/gen/body_<lang>.tex from plain/data/*.json
# Usage: gen.pl [lang ...]   (default: en es fr)
# Files are rewritten only when their content changes, so make can skip
# recompiling languages that are untouched.
use strict;
use warnings;
use utf8;
use JSON::PP;
use Encode qw(encode);
use File::Path qw(make_path);
use File::Basename qw(dirname);

chdir dirname(__FILE__) . '/..' or die "chdir: $!";

my $ME   = 'V. Castor-Villegas';
my $DATA = 'plain/data';
my $OUT  = 'plain/gen';
my @langs = @ARGV ? @ARGV : qw(en es fr);

make_path($OUT);

sub slurp {
  my ($file) = @_;
  open my $fh, '<:raw', $file or die "$file: $!";
  local $/;
  return <$fh>;
}

my $json = JSON::PP->new->utf8;
my %DB = map { $_ => $json->decode(slurp("$DATA/$_.json")) }
         qw(education work publications skills languages);

# Pick the string for a language: plain strings are shared by all languages,
# hashes are {en => ..., es => ..., fr => ...}
sub L {
  my ($v, $lang) = @_;
  return ref $v eq 'HASH' ? $v->{$lang} : $v;
}

sub headings_section {
  my ($db, $lang) = @_;
  my $tex = "\\section{" . L($db->{section}, $lang) . "}\n";
  $tex .= "\\resumeSubHeadingListStart\n";
  for my $e (@{$db->{entries}}) {
    $tex .= "\n  \\resumeSubheading\n";
    $tex .= "    {" . L($e->{title}, $lang) . "}{" . L($e->{dates}, $lang) . "}\n";
    $tex .= "    {" . L($e->{institution}, $lang) . "}{" . L($e->{location}, $lang) . "}\n";
    if ($e->{items} && @{$e->{items}}) {
      $tex .= "  \\resumeItemListStart\n";
      $tex .= "    \\resumeItem{" . L($_, $lang) . "}\n" for @{$e->{items}};
      $tex .= "  \\resumeItemListEnd\n";
    }
  }
  $tex .= "\n\\resumeSubHeadingListEnd\n";
  return $tex;
}

sub publications_section {
  my ($db, $lang) = @_;
  my $tex = "\\pubbreak\n\\section{" . L($db->{section}, $lang) . "}\n";
  my $resume = "";
  for my $g (@{$db->{groups}}) {
    $tex .= "\\pubgroup{" . L($g->{label}, $lang) . "}\n";
    $tex .= "\\begin{enumerate}[leftmargin=0.2in$resume]\n  \\small\n";
    for my $p (@{$g->{entries}}) {
      my $title = $p->{url} ? "\\href{$p->{url}}{$p->{title}}" : $p->{title};
      (my $authors = $p->{authors}) =~ s/\Q$ME\E/\\textbf{$ME}/;
      $tex .= "  \\item $authors. $title.";
      if ($p->{journal}) {
        my $ref = "\\emph{$p->{journal}}";
        $ref .= " $p->{volume}"   if $p->{volume};
        $ref .= "($p->{number})"  if $p->{number};
        $ref .= ", $p->{year}";
        $tex .= " $ref.";
      }
      $tex .= " \\pubnote{$p->{note}}" if $p->{note} && $lang eq 'en';
      $tex .= "\n";
    }
    $tex .= "\\end{enumerate}\n";
    $resume = ", resume";
  }
  return $tex;
}

sub skills_section {
  my ($db, $lang) = @_;
  my $tex = "\\section{" . L($db->{section}, $lang) . "}\n";
  $tex .= "\\begin{itemize}[leftmargin=0in, label={}]\n  \\small{\\item{\n";
  my @cats = @{$db->{categories}};
  for my $i (0 .. $#cats) {
    my $c = $cats[$i];
    $tex .= "    \\textbf{" . L($c->{label}, $lang) . "}\\hspace{2pt}:\\hspace{4pt}"
          . L($c->{items}, $lang);
    $tex .= "\n      \\vspace{2pt}\\\\" if $i < $#cats;
    $tex .= "\n";
  }
  $tex .= "  }}\n\\end{itemize}\n";
  return $tex;
}

sub languages_section {
  my ($db, $lang) = @_;
  my $tex = "\\section{" . L($db->{section}, $lang) . "}\n";
  $tex .= "\\begin{itemize}[leftmargin=0in, label={}]\n  \\small{\\item{\n";
  my @e = @{$db->{entries}};
  for my $i (0 .. $#e) {
    my $sep = $i < $#e ? "\\hspace{12pt}" : "";
    $tex .= "    \\textbf{" . L($e[$i]{label}, $lang) . "}\\hspace{2pt}:\\hspace{4pt}"
          . "$e[$i]{level}$sep\n";
  }
  $tex .= "  }}\n\\end{itemize}\n";
  return $tex;
}

sub write_if_changed {
  my ($file, $content) = @_;
  my $bytes = encode('UTF-8', $content);
  return 0 if -e $file && slurp($file) eq $bytes;
  open my $fh, '>:raw', $file or die "$file: $!";
  print {$fh} $bytes;
  close $fh;
  return 1;
}

for my $lang (@langs) {
  my $body = join "\n", map { "$_\\sectiongap\n" }
    headings_section($DB{education}, $lang),
    headings_section($DB{work}, $lang),
    skills_section($DB{skills}, $lang),
    languages_section($DB{languages}, $lang),
    publications_section($DB{publications}, $lang);
  write_if_changed("$OUT/body_$lang.tex", $body);
}

