#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;

use Scalar::Util qw/weaken/;

use_ok("Tie::RefHash::Weak");

tie my %hash, "Tie::RefHash::Weak";

isa_ok(tied %hash, "Tie::RefHash::Weak", 'tied(%hash)');

my $val = "foo";

$hash{blah} = $val;
is_deeply([ keys %hash ], [ "blah" ], "keys returns 'blah'");

is($hash{blah}, $val, "normal string as key");

my $delete_is_borked;
SKIP: {
	my $deleted = delete($hash{blah});
	
	use Tie::RefHash;
	tie my %refhash, 'Tie::RefHash';
	$refhash{foo} = 1;
	my $r = [];
	$refhash{$r} = 2;

	unless (delete($refhash{foo}) == 1 and delete($refhash{$r}) == 2) {
		$delete_is_borked=1;
		skip "Tie::RefHash::delete is broken", 1;
	}
	
	is($deleted, $val, "delete returns value");
}
ok(!exists($hash{blah}), "deleted value no longer exists()");

my $ref = \$val;

$hash{$ref} = $val;
is($hash{$ref}, $val, "ref as key");
is_deeply([ keys %hash ], [ $ref ], "keys returns ref");
ok(exists($hash{$ref}), "existing value exists()");
SKIP: {
	my $deleted = delete($hash{$ref});
	skip "Tie::RefHash::delete is broken", 1 if $delete_is_borked;
	is($deleted, $val, "delete returns value");
}
ok(!exists($hash{$ref}), "deleted value no longer exists()");
is_deeply([ keys %hash ], [ ], "no keys in hash");


{
	my $goner = "blech";
	$ref = \$goner;
	weaken($ref);

	$hash{$ref} = "foo";

	is($hash{$ref}, "foo", "ref as key");
	is_deeply([ keys %hash ], [ $ref ], "keys returns ref");
	ok(exists($hash{$ref}), "existing value exists()");
}

# $goner has droppped out of scope
is($ref, undef, "reference was undefined");

is_deeply([ values %hash ], [], "no values in hash");

is(scalar keys %hash, 0, "scalar keys returns 0");
is_deeply([ keys %hash ], [] , "keys returns emtpy list");

