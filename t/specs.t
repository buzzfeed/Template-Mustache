use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use FindBin '$Bin';
use Test::More tests => 124;
use Template::Mustache;
use YAML::Syck;

my $PARTS_DIR = "$Bin/partials/";
$Template::Mustache::template_path      = $PARTS_DIR;
$Template::Mustache::template_extension = '';

sub startup {
	# remove partials directory
	&shutdown();

	# create partials directory
	make_path( $PARTS_DIR, { error => \my $err } );
	if ( @$err ) {
		for my $diag ( @$err ) {
			my ($file, $message) = %$diag;
			if ($file eq '') {
				die "General error: [$message]";
			}
			else {
				die "Can't create [$file]: [$message]";
			}
		}
	}
}

sub setup {
	my $t = shift;

	# create and fill partials files
	foreach my $k ( keys %{ $t->{partials} } ) {
		my $parts_filename = $PARTS_DIR . $k;

		open my $fh, '>', $parts_filename
			or die "Can't create [$parts_filename]: [$!]";
		print $fh $t->{partials}->{$k};
		close $fh;
	}
}

sub teardown { }

sub shutdown {
	# remove partials directory
	remove_tree( $PARTS_DIR, { error => \my $err } );
	if ( @$err ) {
		for my $diag ( @$err ) {
			my ($file, $message) = %$diag;
			if ($file eq '') {
				die "General error: [$message]";
			}
			else {
				die "Can't remove [$file]: [$message]";
			}
		}
	}
}

while ( my $filename = <$Bin/../ext/spec/specs/*.yml> ) {
	startup();

	my $spec  = LoadFile($filename);
	my $tests = $spec->{tests};

	note "\n---------\n$spec->{overview}";

	foreach my $t ( @{$tests} ) {
		setup($t);

		$t->{signature} = "$t->{name}\n$t->{desc}\n";
		my $out = '';

		eval {
			# TODO: partials from file
			$out = Template::Mustache->render( $t->{template}, $t->{data}, $t->{partials} );
		};
		if ( $@ ) {
			fail( $t->{signature} . "ERROR: $@" );
		}
		else {
			is $out => $t->{expected}, $t->{signature};
		}

		teardown($t);
	}

	&shutdown();
}
