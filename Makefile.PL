#!/usr/bin/perl

use 5.010001;
use ExtUtils::MakeMaker;
use strict;
use warnings;
use FindBin qw/$Bin/;
use Cwd;

my $DEBUG = 0;

# Writing Makefile
my %QMAKE;
my $LIB_DIR = "$Bin/qtclass/";

# Making Qt class static library first
my $out; 
my $old_dir = cwd($LIB_DIR);
$out = `cd $LIB_DIR && qmake 2>&1`;
$? ? die "Can't run qmake: " . $out : print "Running qmake\n";

$out = `cd $LIB_DIR && make 2>&1`;
$? ? die "Can't make Qt class:" . $out : print "Running make\n";


# Writing Makefile for the Perl module
my @files = qw/libqt_webkit.prl Makefile/;

foreach my $file ( map { $LIB_DIR . $_ } @files ) {
	open( my $fh, "<", $file ) or die "Can't open file $file: $!";
	while ( my $line = <$fh> ) {
		$QMAKE{ $1 } = $2 if ( $line =~ /^(INCPATH|QMAKE_PRL_LIBS)\s*=\s*(.*)$/ );
	}
	close $fh;
}

my $CC = 'g++';

WriteMakefile(
    NAME              => 'Webkit',
    VERSION_FROM      => 'lib/Webkit.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ( $] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Webkit.pm',
       AUTHOR         => 'Ivan Kapelyukhin <ikapelyukhin@gmail.com>') : ()
    ),
    LIBS => [
    	"-L$LIB_DIR -lqt_webkit " . $QMAKE{QMAKE_PRL_LIBS}
    ],
    DEFINE            => '',
    INC               => $QMAKE{INCPATH},
    CC                => $CC,
    CCFLAGS           => ( $DEBUG ? ' -ggdb' : '' ),
    LD                => '$(CC)',
    XSOPT             => '-C++',
    TYPEMAPS          => [
        'perlobject.map',
        'qstring.map',
    ],
);

$out = `cd $LIB_DIR && make clean`;
