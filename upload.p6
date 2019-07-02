#!/usr/bin/env perl6

use JSON::Fast;

sub mixtape-parse(Str $mix --> Str) {
	my %res = from-json $mix;
	unless %res<success> {
		die "mixtape.moe error " ~ %res;
	}

	%res<files>[0]<url>;
}
sub hastebin-parse($haste) {
	my %res = from-json $haste;
	unless %res<key> {
		die "hastebin error " ~ %res;
	}
	"https://hastebin.com/" ~ %res<key>;
}

sub id($x) { $x; }

sub uploader($url, $param, $fname, $upload-char, $additional-params) {
	(run qqx/curl -sS -F "$param=$upload-char$fname" $additional-params $url/).command[0].chomp;
}

sub print-and-copy(Str $s) {
	say $s;
	shell "echo \"$s\"|xsel -i -b";
}

sub manage_uploads(Str $url, Str $param, :&postprocess=&id, :$upload-char="@", :$additional-params="") {
	my @uploads;
	if (@*ARGS.elems == 1) {
		@uploads.push("-");
	} else {
		@uploads = @*ARGS[1 .. *];
	}

	for @uploads -> $x is copy {
		# if it doesn't have a files extension, force curl to name it 't.txt' so some file hosts will add a file extension of .txt
		if $x.split('/').tail.split('.').elems == 1 {
			$x ~= ";filename=t.txt";
		}
		print-and-copy(postprocess(uploader($url, $param, $x, $upload-char, $additional-params)));
	}
}

given @*ARGS[0] {
	when "0x0" { manage_uploads("https://0x0.st", "file"); }
	when "catbox" { manage_uploads("https://catbox.moe/user/api.php", "fileToUpload", additional-params => "-Freqtype=fileupload"); }
	when "sprunge" { manage_uploads("http://sprunge.us", "sprunge"); }
	when "ix" { manage_uploads("http://ix.io", "f:1"); }
	when "haste" { manage_uploads("https://hastebin.com/documents", "data", postprocess => &hastebin-parse, upload-char => "<"); }
	when Str { die "Unknown host @*ARGS[0]"; }
	default { die "No host given!"; }
}
