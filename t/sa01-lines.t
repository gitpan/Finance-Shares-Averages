#!/usr/bin/perl
use strict;
use warnings;
use Test;
BEGIN { plan tests => 11 };

use PostScript::File qw(check_file);
use PostScript::Graph::Style;
use Finance::Shares::Sample;
use Finance::Shares::Averages;
ok(1);

my $pf = new PostScript::File(
	errors => 1,
	debug => 1,
	paper => 'A4',
	landscape => 1,
    );
ok($pf);
    
my $s = new Finance::Shares::Sample(
	source	    => 't/LLOY_L.csv',
	epic	    => 'LLOY.L',
	by	    => 'data',
	graph	    => {
	    file => $pf,
	    color => [0.6, 0.8, 0.9],
	    price   => {
		style => {
		    point => {
			shape => 'stock',
			width => 4,
		    },
		},
	    },
	    volume  => {
		style => {
		    bar => {
			color => [0.8, 0.8, 0.9],
		    },
		},
	    },
	    smallest=> 3,
	},
	lines => {
	    width => 1.5,
	    line    => {
		color => [0.3, 0.6, 0.9],
	    },
	    point   => {
		color => [0, 1, 1],
	    },
	},
    );
ok($s);

$s->simple_average(1,1, 'price', 4);
ok(1);
$s->simple_average(1,1, 'volume', 4);
ok(1);
$s->weighted_average(1,1, 'volume', 8);
ok(1);
$s->exponential_average(1,1, 'volume', 12);
ok(1);
$s->weighted_average(0,1, 'price', 8);
ok(1);
$s->exponential_average(0,1, 'price', 12);
ok(1);

my $name = "st01-lines";
$s->output( $name, 'test-results' );
ok(1);
my $file = check_file( "$name.ps", 'test-results' );
ok($file);

