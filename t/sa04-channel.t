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
    #source	    => 't/shell.csv',
    #epic	    => 'SHEL.L',
	source	    => 't/ulvr.csv',
	epic	    => 'ULVR.L',
	#dates_by    => 'weeks',
	graph	    => {
	    file    => {
		debug => 1,
	    },
	    dates => {
		by => 'weeks',
	    },
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

$s->simple_average(1,1, 'price', 4);
ok(1);

my $style = new PostScript::Graph::Style(
	sequence => $pseq,
	label => 'channel',
	line => {
	    color => [1, 0, 0],
	    dashes => [],
	},
    );
ok($style);
$pseq->reset();

$s->channel(1,1, 'price', 'simple', 4, 2, $style);
ok(1);
$s->channel(1,1, 'volume', 'simple', 1, 10, $style);
ok(1);

my $name = 'st04-channel';
$s->output( $name, 'test-results' );
ok(1); # survived so far
my $file = check_file( "$name.ps", 'test-results' );
ok($file);

