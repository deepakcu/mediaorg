package MediaIndex;

use autodie;
use Digest::MD5 'md5_hex';
use Image::ExifTool 'ImageInfo';
use Path::Class;
use File::Path qw(make_path);
use File::Copy;
use File::Basename;
use File::Spec;

use Exporter qw(import);
our @EXPORT_OK = qw(index_media); 

sub index_media {
    my $src_path = shift;
    # create index file
    open(my $media_fh, '>', 'media.idx');
    open(my $skipped_fh, '>', 'skipped.idx');
    index_files($media_fh, $skipped_fh, $src_path);
    close $media_fh;
    close $skipped_fh;
}

sub index_files {
    my $media_fh = shift;
    my $skipped_fh = shift;
    my $path = shift;
    print "path = $path\n";    
    # Open the directory.
    opendir (DIR, $path)
        or die "Unable to open $path: $!";

    # Read in the files.
    # You will not generally want to process the '.' and '..' files,
    # so we will use grep() to take them out.
    # See any basic Unix filesystem tutorial for an explanation of them.
    my @files = grep { !/^\.{1,2}$/ } readdir (DIR);

    # Close the directory.
    closedir (DIR);

    # At this point you will have a list of filenames
    #  without full paths ('filename' rather than
    #  '/home/count0/filename', for example)
    # You will probably have a much easier time if you make
    #  sure all of these files include the full path,
    #  so here we will use map() to tack it on.
    #  (note that this could also be chained with the grep
    #   mentioned above, during the readdir() ).
    @files = map { $path . '/' . $_ } @files;

    my $idx_cnt = 0;
    for (@files) {
        # If the file is a directory
        if (-d $_) {
            # Here is where we recurse.
            # This makes a new call to index_files()
            # using a new directory we just found.
            index_files ($media_fh, $skipped_fh, $_);

        # If it isn't a directory, lets just do some
        # processing on it.
        } else { 
            # Do whatever you want here =) 
            # A common example might be to rename the file.
            my $exif = Image::ExifTool->new;

            # extract timestamp info
            $exif->ExtractInfo($_);
            my $date = $exif->GetValue('DateTimeOriginal', 'PrintConv');
            # extract year, month, day from the string "y:m:d time"
            my $ymd = (split / /, $date)[0];
            my ($year, $month, $date) = $ymd =~ /(\d+):(\d+):(\d+)/;
            my ($volume,$directories,$file) = File::Spec->splitpath( $_ );
            my $tgt_name = "pics_".$year."_".$month."_".$date."/".$file;
            my $src_name = $_;
            if (!defined $date) {
                print "Exif data not found. Skipping $_\n";
                print $skipped_fh "$src_name\n";
            } else {
                print $media_fh "$src_name,$tgt_name\n";
                $idx_cnt++;
            }
      }
   }
   print "Total $idx_cnt files indexed\n";
}
1;
