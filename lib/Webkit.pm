package Webkit;

use 5.010001;
use strict;
use warnings;

#require Exporter;
#
#our @ISA = qw(Exporter);
#
#our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#our @EXPORT = qw( );

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Webkit', $VERSION);

1;
__END__
=head1 NAME

Webkit - Perl interface to QtWebkit

=head1 SYNOPSIS

  use Webkit;
  
  my $w = Webkit->new();
  $w->setResponseCallback( sub {
	  my ( $w, $ok ) = @_;
	  die "Something went wrong" unless ( $ok );
	  print $w->getContent();
  } );
  $w->get("http://perl.org");

=head1 DESCRIPTION

This is a Perl interface to QtWebkit. This module allows to load pages using Webkit and execute JavaScript code.
Also this module provides callbacks for various events.

This module adds C<__bridge> global JavaScript object to every page. It has two methods:

=over 4

=item * bridgeCallback() 

See Webkit::setBridgeCallback() method

=item * finish()

See Webkit::finish() method

=back

=head1 METHODS

=head2 new()

=head2 new( $params )

Returns new Webkit object.

$params is a hash reference. The following keys can be set:

=over 4

=item * NoImages - images won't be loaded if true value is set; default is 0.

=item * UserAgent - specified value is sent in User-Agent HTTP request field. By default QtWebkit default value is used.

=back

=head2 get( $url )

=head2 get( $url, $params )

Starts Qt event loop and loads specified URL. When the URL loaded response callback is called.

This method returns error code. Non-zero code means an error ocurred.

$params is a hash reference. The following keys can be set:

=over 4

=item * Timeout - timeout in milliseconds. If the page isn't loaded in given time the request will terminate and return control back to perl.

=back

=head2 evaluateJavaScript()

Evaluates supplied string as JavaScript code. Evaluation result is converted into corresponding Perl types (hashes, arrays, etc.)

	use Data::Dumper;
	my $Webkit = Webkit->new();

	print Dumper $Webkit->evaluateJavaScript("var result = { foo: 1, bar: [1, 2, 3], baz: "string"}; result;");

=head2 setResponseCallback()

Sets the response callback. Callback subroutine recieves caller Webkit object as the first parameter and request status as the second.

If callback subroutine returns a code reference, the event loop continues and given subroutine will be called next time the page is loaded. Otherwise the event loop finishes.

See L<SYNOPSIS> section for a simple example.

=head2 setAlertCallback()

Sets callback for JavaScript alert() function. Callback subroutine recieves caller Webkit object as the first parameter and alert message as the second parameter.

	my $Webkit = Webkit->new();
	$Webkit->setAlertCallback( sub { printf("Alert: %s\n", shift); } );
	$Webkit->evaluateJavaScript("alert('Hello, world!');");

=head2 setConsoleCallback()

Sets callback for JavaScript console.log() and console.warn() methods. Callback subroutine recieves caller Webkit object as the first parameter and message as the second parameter.
Errors in JavaScript syntax are reported here.

	my $Webkit = Webkit->new();
	$Webkit->setConsoleCallback( sub { printf("Console: %s\n", shift); } );
	$Webkit->evaluateJavaScript("console.log('Hello, world!');");
	$Webkit->evaluateJavaScript("somerandomfunction();"); # calling undefined JavaScript function

=head2 setConfirmCallback()

Sets callback for JavaScript confirm() function. Callback subroutine recieves caller Webkit object as the first parameter and confirm message as the second parameter.
True return value works as "Yes" button in JavaScript confirm dialog, as "No" button otherwise.

	my $Webkit = Webkit->new();
	$Webkit->setConfirmCallback( sub {
		my ( $Webkit, $message ) = @_;
		return $message eq "yes" ? 1 : 0;
	} );
	$Webkit->evaluateJavaScript( "confirm('yes');" ); # returns true
	$Webkit->evaluateJavaScript( "confirm('no');"  ); # returns false

=head2 setPromptCallback()

Sets callback for JavaScript prompt() function. Callback subroutine recieves caller Webkit object as the first parameter, prompt as the second parameter, default value as the third parameter.
True return value works as input in prompt dialog box, false value works as "Cancel" button.

	my $Webkit = Webkit->new();
	
	$Webkit->setAlertCallback( sub { my ($w, $msg) = @_; printf("Alert: %s\n", $msg); } );

	$Webkit->setPromptCallback( sub {
		my ( $prompt, $default ) = shift;
		return $prompt eq "yes" ? $default : undef;
	} );

	$Webkit->evaluateJavaScript( "alert( prompt("yes", "default value 1") );" );
	$Webkit->evaluateJavaScript( "alert( prompt("no",  "default value 2") );" );

=head2 setBridgeCallback()

Sets callback for __bridge.bridgeCallback() function. Recieves caller Webkit object as the first parameter, argument passed from JavaScript as second parameter.

Doesn't return anything back to JavaScript.

	use Data::Dumper;
	my $Webkit = Webkit->new();

	# Save arguments passed from JavaScript to file
	$Webkit->setBridgeCallback( sub {
		my ( $Webkit, $args ) = @_;

		open ( my $file, ">", "dump.dat" );
		print $file Dumper( $args );
		close $file;
	} );

	$Webkit->setResponseCallback( sub {
		my ( $Webkit, $ok ) = @_;

		$Webkit->evaluateJavaScript( q^
			var data = getAwesomeDataFromSomewhere();
			__bridge.bridgeCallback( data );
		^ );
	} );

	$Webkit->get( "http://somesite.url" );

=head2 getUrl()

Returns current URL.

=head2 getContent()

Returns source code of currently loaded page.

=head2 finish()

Stops the event loop.

=head1 DEPENDENCIES

Qt is required to build this module. This module is written and tested with Qt 4.8.

It is possible to use this module without X Server if linked against wkhtmltopdf patched Qt (see link below).

=head1 SEE ALSO

=over 4

=item * L<http://qt-project.org/doc/>

=item * L<http://qt.gitorious.org/qt/wkhtmltopdf-qt>

=item * L<http://code.google.com/p/wkhtmltopdf/>

=back

=head1 AUTHOR

Ivan Kapelyukhin, E<lt>ikapelyukhin@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Ivan Kapelyukhin

perl-qtwebkit is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

perl-qtwebkit is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with perl-qtwebkit. If not, see <http://www.gnu.org/licenses/>.

=cut
