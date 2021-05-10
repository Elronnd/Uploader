#!/usr/bin/env perl6

use JSON::Fast;

sub id($x) { $x; }

sub pipe-to($what, @command) {
	my $ret = run |@command, :in, :out;
	$ret.in.spurt: $what, :close;
	$ret
}

sub uploader($sponge, $url, $param, $fname, $upload-char, $additional-params) {
	my @command = «curl -sS -F "$param=$upload-char$fname" $additional-params $url»;
	my $cmd;
	if $sponge {
		$cmd = pipe-to $*IN.slurp, @command;
	} else {
		$cmd = run |@command, :out;
	}

	chomp $cmd.out.slurp: :close;
}

sub print-and-copy(Str $s) {
	say $s;
	pipe-to $s, <xsel -i -b>;
}

sub manage_uploads(Str $url, Str $param, :&postprocess=&id, :$upload-char="@", :$additional-params="") {
	my $sponge = False;
	my @uploads;
	if (@*ARGS.elems == 1) {
		@uploads.push("-");
		$sponge = True;
	} else {
		@uploads = @*ARGS[1 .. *];
	}

	for @uploads -> $x is copy {
		# if it doesn't have a files extension, force curl to name it 't.txt' so some file hosts will add a file extension of .txt
		if $x.split('/').tail.split('.').elems == 1 {
			$x ~= ";filename=t.txt";
		}
		print-and-copy(postprocess(uploader($sponge, $url, $param, $x, $upload-char, $additional-params)));
	}
}

given @*ARGS[0] {
	when "0x0" { manage_uploads("https://0x0.st", "file"); }
	when "catbox" { manage_uploads("https://catbox.moe/user/api.php", "fileToUpload", additional-params => "-Freqtype=fileupload"); }
	when "sprunge" { manage_uploads("http://sprunge.us", "sprunge"); }
	when "ix" { manage_uploads("http://ix.io", "f:1"); }
	when Str { die "Unknown host @*ARGS[0]"; }
	default { die "No host given!"; }
}
