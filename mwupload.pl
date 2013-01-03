#!/usr/bin/perl -w

# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

# TODO
# Check for duplicate titles
# Make it possible to harvest just a given list of sets from a repository
# Make it possible to specify the metadataformat to be harvested per repository
# Fix the "path" part of the wiki setup

use MediaWiki::API;
use File::Slurp;
use YAML::Syck qw'LoadFile';
use Data::Dumper;
use Term::ANSIColor;
use Getopt::Long;
use Pod::Usage;
use Modern::Perl;

my ($config_file, $images, $comment, $delete, $limit, $verbose, $debug) = get_options();

# Open the config
my $config;
if ( -e $config_file ) {
	$config = LoadFile( $config_file );
} else {
	die "Could not find $config_file\n";
}

# Read the image names
my @img;
if ( -e $images ) {
    @img = read_dir( $images );
}
@img = sort @img;

my $mw = MediaWiki::API->new( { 'api_url' => $config->{'api_url'} }  );
$mw->login( { 'lgname' => $config->{'lgname'}, 'lgpassword' => $config->{'lgpassword'} } )
    || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

# Loop through all the images
my $count    = 0;
my $uploaded = 0;
my $failed   = 0;
foreach my $image ( @img ) {

    # Skip hidden files
    next if substr $image, 0, 1 eq '.';

    my $fullpath = $images . $image;
    say "*** Going to upload $fullpath as $image";

    # Attempt upload
    if ( $mw->edit({
        action   => 'upload',
        filename => $image,
        comment  => $comment,
        file     => [ $fullpath ],
    }) ) { 
        # Success
        $uploaded++;
        if ( $delete ) {
            if ( unlink $fullpath ) {
                say colored ['bright_green'], "\t$fullpath deleted";
            } else { 
                warn colored ['bright_red'], "Could not unlink $fullpath: $!"; 
            }
        }
    } else {
        # Failure
        warn colored ['bright_red'], "\t", $mw->{error}->{code} . ': ' . $mw->{error}->{details};
        $failed++;
    }
    
    $count++;
    if ( $limit && $limit == $count ) {
        exit;
    }
}

$mw->logout();

say "$count images processed - $uploaded uploaded, $failed failed";

### SUBROUTINES

# Get commandline options
sub get_options {
  my $config  = '';
  my $images  = '';
  my $comment = '';
  my $delete  = '';
  my $limit   = 0;
  my $verbose = '';
  my $debug   = '';
  my $help    = '';

  GetOptions("c|config=s"  => \$config,
             "i|images=s"  => \$images, 
             "m|comment=s" => \$comment, 
             "delete"      => \$delete, 
             "l|limit=i"   => \$limit,
             "v|verbose"   => \$verbose,
             "d|debug"     => \$debug,
             "h|help"      => \$help,
             );
  
  pod2usage(-exitval => 0) if $help;
  pod2usage( -msg => "\nMissing Argument: -c, --config required\n", -exitval => 1) if !$config;
  pod2usage( -msg => "\nMissing Argument: -i, --images required\n", -exitval => 1) if !$images;

  return ($config, $images, $comment, $delete, $limit, $verbose, $debug);
}       

__END__

=head1 NAME
    
mwupload.pl - Upload all images in a directory to a MediaWiki site
        
=head1 SYNOPSIS
            
mwupload.pl -c myconfig.yaml -i ~/myimages --delete -m "Photos by N.N. [[Category:Holiday]]"

=head1 OPTIONS
              
=over 8

=item B<-c, --config>

Path to a config file in YAML format. 

=item B<-i, --images>

Path to directory that contains images. 

=item B<-m, --comment>

Text string that will be associated with the uploaded image as a comment. 

=item B<--delete>

Delete images after they have been successfully uploaded. 

=item B<-l, --limit>

Max number of images to handle. 

=item B<-v, --verbose>

Turn on verbose output. 

=item B<-d, --debug>

Turn on debug output. 

=item B<-h, --help>

Print this documentation. 

=back

=head1 RESIZE IMAGES WITH convert

for i in *.jpg; do convert "$i" -resize 90% "$i"; done
                                                       
=cut
