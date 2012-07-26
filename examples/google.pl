#!/usr/bin/perl

# This script gets the first ten Google search results for "Perl" query

use strict;
use warnings;

use Webkit;
use Data::Dumper;
use URI::Escape;

my $Webkit = Webkit->new();
my $links;

$Webkit->setConsoleCallback( sub { printf("Console: %s\n", $_[1]); } );

$Webkit->setResponseCallback( sub {
	my ( $Webkit, $ok ) = @_;
	die "Something went wrong" unless ( $ok );

	$Webkit->evaluateJavaScript( q^
		function waitForLoad() {
			if ( document.readyState == "complete" ) {
				var input = document.querySelector("input[name=q]");
				if ( !input ) {
					console.log("Can't find search query input field. Bailing out.");
					__bridge.finish();
				} else {
					input.value = "Perl";
					input.form.submit();
				}
			} else {
				setTimeout( "waitForLoad()", 500 );
			}
		}

		waitForLoad();
	^ );

	return sub {
		my ( $Webkit, $ok ) = @_;

		die "Something went wrong" unless ( $ok );
		
		$links = $Webkit->evaluateJavaScript(q^
			var array = new Array();
			var links = document.querySelectorAll("li.g .r a");
			for ( var i = 0; i < links.length; i++ ) {
				array.push( links[i].href );
			}
			array;
		^);
	};
} );

die "Qt event loop exited with code $_" if ( $Webkit->get("http://google.ru") );

$links = [ map { $_ =~ /\?q=(.*?)&/ ? uri_unescape($1) : undef } @$links ];
print Dumper $links;
