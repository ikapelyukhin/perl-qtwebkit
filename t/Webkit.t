#!/usr/bin/perl

use ExtUtils::testlib;
use Test::More tests => 16;

use strict;
use warnings;

BEGIN { 
	use_ok('Webkit');
	use_ok('Test::LeakTrace');
};

my $w = Webkit->new();

# Type conversion
{
	my $data;
	no_leaks_ok {
		$data = $w->evaluateJavaScript(q^
			var data = {
				int: 42,
				str: "the ultimate answer",
				bool: false,
				hash: { foo: 1, bar: 2 },
				arr: [1, 2, 3]
			};
			data;
		^);
	} 'no leaks in type conversion';

	is_deeply(
		$data,
		{ int => 42, str => "the ultimate answer", bool => '', hash => { foo => 1, bar => 2 }, arr => [ 1, 2, 3 ] },
		"QVariant conversion"
	);
}

# JS callbacks
{
	my $result;
	no_leaks_ok {
		$w->setAlertCallback( sub { my ( $w, $msg ) = @_; $result = $msg; } );
		$w->evaluateJavaScript( q^alert("foo");^ );
	} 'no leaks in alert callback';
	is( $result, "foo", "Alert callback" );
}

{
	my ( $result, $result2 );
	no_leaks_ok {
		$w->setConsoleCallback( sub { my ( $w, $msg, $line ) = @_; $result = $msg; $result2 = $line; } );
		$w->evaluateJavaScript( q^console.log("bar");^ );
	} 'no leaks in console callback';
	ok( ( $result eq "bar" and defined( $result2 ) ), "Console callback" );
}

{
	my ( $result, $result2 );
	no_leaks_ok {
		$w->setConfirmCallback( sub {
			my ( $w, $msg ) = @_;
			return $msg eq "yes" ? 1 : 0;
		} );
		
		$result  = $w->evaluateJavaScript( q^var res = confirm("yes"); res;^ );
		$result2 = $w->evaluateJavaScript( q^var res = confirm("no");  res;^ );
	} 'no leaks in confirm callback';

	ok( $result && !$result2, "Confirm callback" );
}

{
	my ( $result, $result2 );
	my $default_retval = "default retval";

	no_leaks_ok {
		$w->setPromptCallback( sub {
			my ( $w, $msg, $default_retval ) = @_;
			return $msg eq "yes" ? $default_retval : undef;
		} );
	
		$result  = $w->evaluateJavaScript( qq^var res = prompt( "yes", "$default_retval" ); res;^ );
		$result2 = $w->evaluateJavaScript( qq^var res = prompt( "no",  "$default_retval" ); res;^ );
	} 'no leaks in prompt callback';

	ok( $result eq $default_retval && !$result2, "Prompt callback" );
}

# Network dependent tests

my $net_available;
SKIP: {
	my ( $result, $result2, $ok );
	my $w = Webkit->new();

	no_leaks_ok {
		$w->setBridgeCallback( sub { $result = 1; } );
	} 'no leaks in bridge callback';

	$w->setResponseCallback( sub {
		my $w = shift;
		$ok = shift;

		return 0 unless $ok;

		my $test = $w->evaluateJavaScript(q^
			var check;
			if (
				typeof( __bridge ) !== 'undefined' &&
				typeof( __bridge.bridgeCallback !== undefined ) &&
				typeof( __bridge.finished !== undefined )
			) {
				check = 1;
				__bridge.bridgeCallback();
			}
			check;
		^);

		$result2 = 1 if ( $w->getContent() =~ /The Perl Programming Language/i );
		
		return 0;
	} );

	if ( !$w->get("http://perl.org/") && $ok ) {
		ok( $result && $result2, "Bridge, getContent checks" );
		$net_available = 1;
	} else {
		skip( "Can't connect to perl.org. The network is down?", 1 );
	}
}

SKIP: {
	if ( $net_available ) {
		my $w = Webkit->new();

		$w->setResponseCallback( sub {
			return sub { }; # does nothing. Should hang the event processing loop.
		} );

		eval {
			local $SIG{ALRM} = \&die;
			alarm( 10000 );
			$w->get( "http://perl.org", { Timeout => 2000 } ); # Just any URL really.
		};

		ok( !$@, "QTimer timeout" );
	} else {
		skip( "Network not available." );
	}
}

SKIP: {
	if ( $net_available ) {
		my $w = Webkit->new();

		$w->setResponseCallback( sub {} );
		$w->get( "http://perl.org" );
		$w->get( "http://perl.org" );
		pass( "Event loop check, callbacks reuse check." );
	} else {
		skip( "Network not available." );
	}
}

done_testing();

