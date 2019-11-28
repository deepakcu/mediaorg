package MediaCopy;

use autodie;
use Digest::MD5 'md5_hex';
use Image::ExifTool 'ImageInfo';
use Path::Class;
use File::Path qw(make_path);
use File::Copy;
use File::Basename;
use MediaHelper;

use Exporter qw(import);
our @EXPORT_OK = qw(copy_media); 

sub copy_media {
    open(my $fh, '<:encoding(UTF-8)', 'media.idx') or die "Could not open file source.idx $!";
    my $copy_cnt = 0;       
    while (my $row = <$fh>) {
        chomp $row;
        my $source = (split(',',$row))[0];
        my $target = (split(',',$row))[1];
        my ($volume,$tdir,$file) = File::Spec->splitpath( $target );

	if (!(-e $tdir and -d $tdir)) {
		# directory doesn't exist, create it
		eval { make_path($tdir) };
		if ($@) {
			print "Couldn't create $tdir: $@";
			return;
		}
	}

	if(!(-e $tfname)) {
		#move($source, $tdir) or die "Copy failed: $!";
                print("Copying $source to $target..");
                copy($source, $target) or die "Copy failed: $!";
                $copy_cnt++;
                print("Done\n");
	} else {
		print("Duplicate file found. Skip copy for $_\n");
	}
    }
    print "Total $copy_cnt files copied\n";
    close $fh;
}

1;
