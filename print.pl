#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Text::ASCIITable;

my $dbFile = shift;

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbFile","","",{ RaiseError => 1, AutoCommit => 1 }) ;
my $sth = $dbh->prepare("SELECT * FROM collection");
$sth->execute();
     
my $t = Text::ASCIITable->new({ headingText => 'STATUS' });
$t->setCols(qw(
	Index
	ID
	Title
	Actors
	ImdbRating
	Awards
	Plot
	Year
	Rated
	Type
	Website
	TomatoRating
	Director
	Poster
	Production
	TomatoReview
	Language
	Genre
	RunTime)
);

my $index = 1;
while ( my @row = $sth->fetchrow_array ) {
  $t->addRow($index,@row);
  $index++;
}

$sth->finish;
undef $dbh;
print $t;