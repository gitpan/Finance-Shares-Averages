#!/usr/bin/perl
use strict;
use warnings;
use Test;
BEGIN { plan tests => 8 };

use PostScript::File qw(check_file);
use PostScript::Graph::Style;
use Finance::Shares::Sample;
use Finance::Shares::Averages;

my $s = new Finance::Shares::Sample(
	source	    => 't/LLOY_L.csv',
	epic	    => 'LLOY.L',
	dates_by    => 'data',
	graph	    => {
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

my $graph = $s->graph();
my $pseq = $graph->price_sequence();
ok($pseq);

$s->simple_average(0,1, 'price', 4);
ok(1);

my $style = new PostScript::Graph::Style(
	sequence => $pseq,
	line => {
	    color => [1, 0, 0],
	    dashes => [],
	},
    );
ok($style);
$pseq->reset();

$s->envelope(0,1, 'price', 'simple', 4, 3, $style);
ok(1);
$s->envelope(0,1, 'volume', 'exponential', 4, 10, $style);
ok(1);

my $name = 'st02-envelope';
$s->output( $name, 'test-results' );
ok(1);
my $file = check_file( "$name.ps", 'test-results' );
ok($file);

