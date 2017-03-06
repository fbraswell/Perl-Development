#!/usr/bin/perl -w

# usage
# image_quote.pl

# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/KJV\ iPhone\ Screen\ Shots/ImageDataXML.plist

# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/ASV\ iPhone\ Screen\ Shots/ImageDataXML.plist

# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/ESV\ NAV\ iPhone\ Screen\ Shots/ImageDataXML.plist

# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/KJV\ NAV\ iPhone\ Screen\ Shots/ImageDataXML.plist

# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/ESV\ iPhone\ Screen\ Shots/ImageDataXML.plist

# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/NIV\ iPhone\ Screen\ Shots/ImageDataXML.plist

# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/NASB\ iPhone\ Screen\ Shots/ImageDataXML.plist

# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/SDQ\ iPhone\ Screen\ Shots/ImageDataXML.plist
# ./image_quote.pl /Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/WRDQ\ iPhone\ Screen\ Shots/ImageDataXML.plist

use strict;
use warnings;
# use Data::Plist::Reader;
use Mac::PropertyList qw( :all );
use Data::Dumper qw(Dumper);
use Try::Tiny;
use utf8;
use Text::Unidecode;
use feature 'unicode_strings';
# use POSIX;

# print "\n*********************************** start image_quote.pl  program.***********************************\n";

print "\n******************************* start $0 program. Perl $^V *******************************\n";
# print "Unicode Settings: ${^UNICODE}; Perl Executable: $^X\n";
$| = 1; # flush after every write
$\ = ""; # output record separator

my ($d1) = shift;
my ($getdir, $qv1, $quotetitle) = $d1 =~ /(.*(\/(\w*( NAV)?) iPhone Screen Shots))\//;
# my ($getdir, $qv1, $quotetitle) = $d1 =~ /(.*(\/(\w*) iPhone Screen Shots))\//;


print "\nDirectory: $getdir, Quote Title: $quotetitle\n";

# verse text 1: Psalm 3:8 Salvation belongeth unto the LORD: thy blessing is upon thy people.

# verse text 145: Psalm 62:1 Truly my soul waiteth upon God: from him cometh my salvation. 2 He only is my rock and my salvation; he is my defence; I shall not be greatly moved.
my ($BibleVer, $dir, $vindMatch, $imgMatch, $fn, $fnq);
$dir = $getdir;
$fn =  "$dir/ImageDataXML.plist";
$fnq = "$dir/QuoteDataPlainXML.plist";
$fnq = "$dir/QuoteDataXML.plist";

if($quotetitle eq "KJV"){
# KJV 
# index 145, Psalm 62:1 corresponds to IMG_2709.jpg
$BibleVer = "Psalm Daily Quotes KJV";
# $dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/KJV\ iPhone\ Screen\ Shots/KJV\ images\ all";
$vindMatch = 145; # verse index match
$imgMatch = 2709; # image name match
#$fn =  "$dir/ImageDataXML.plist";
#$fnq = "$dir/QuoteDataPlainXML.plist";
#$fnq = "$dir/QuoteDataXML.plist";
} elsif ($quotetitle eq "ASV"){
#ASV
# index 256, Psalm 119:73 corresponds to IMG_3721.jpg
$BibleVer = "Psalm Daily Quotes ASV";
#$dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/ASV\ iPhone\ Screen\ Shots";
$vindMatch = 256; # verse index match
$imgMatch = 3721; # image name match
#$fn =  "$dir/ImageDataXML.plist";
#$fnq = "$dir/QuoteDataPlainXML.plist";
#$fnq = "$dir/QuoteDataXML.plist";
}elsif($quotetitle eq "ESV NAV"){
#ESV NAV
# index 256, Psalm 119:73 corresponds to IMG_3721.jpg
$BibleVer = "Psalm Daily Quotes ESV NAV";
# $dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/ESV\ NAV\ iPhone\ Screen\ Shots";
$vindMatch = 249; # verse index match
$imgMatch = 2880; # image name match
#$fn =  "$dir/ImageDataXML-ESVNAV.plist";
#$fnq = "$dir/QuoteDataPlainXML-ESVNAV.plist";
#$fnq = "$dir/QuoteDataXML-ESVNAV.plist";
}elsif($quotetitle eq "KJV NAV"){
#KJV NAV
$BibleVer = "Psalm Daily Quotes KJV NAV";
# $dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/KJV\ NAV\ iPhone\ Screen\ Shots";
$vindMatch = 254; # verse index match
$imgMatch = 3343; # image name match
$fn =  "$dir/ImageDataXML-KJVNAV.plist";
$fnq = "$dir/QuoteDataPlainXML-KJVNAV.plist";
$fnq = "$dir/QuoteDataXML-KJVNAV.plist";
}elsif($quotetitle eq "ESV"){
#ESV
$BibleVer = "Psalm Daily Quotes ESV";
#$dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/ESV\ iPhone\ Screen\ Shots";
$vindMatch = 359; # verse index match
$imgMatch = 4648; # image name match
#$fn =  "$dir/ImageDataXML.plist";
#$fnq = "$dir/QuoteDataPlainXML.plist";
#$fnq = "$dir/QuoteDataXML.plist";
}elsif($quotetitle eq "NIV"){
#NIV
$BibleVer = "Psalm Daily Quotes NIV";
#$dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/NIV\ iPhone\ Screen\ Shots";
$vindMatch = 369; # verse index match
$imgMatch = 5423; # image name match
#$fn =  "$dir/ImageDataXML.plist";
#$fnq = "$dir/QuoteDataPlainXML.plist";
#$fnq = "$dir/QuoteDataXML.plist";
}elsif($quotetitle eq "NASB"){
#NASB
$BibleVer = "Psalm Daily Quotes NASB";
#$dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/NASB\ iPhone\ Screen\ Shots";
$vindMatch = 359; # verse index match
$imgMatch = 5435; # image name match
#$fn =  "$dir/ImageDataXML.plist";
#$fnq = "$dir/QuoteDataPlainXML.plist";
#$fnq = "$dir/QuoteDataXML.plist";
}elsif($quotetitle eq "SDQ"){
#SDQ
### !!!!! Be sure to enable alpha sort below for Spurgeon quotes !!!! ####
$BibleVer = "Daily Quotes SDQ";
#$dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/SDQ\ iPhone\ Screen\ Shots";
$vindMatch = 'M3-4.1113'; # verse index match
$imgMatch = 5821; # image name match
#$fn =  "$dir/ImageDataXML.plist";
#$fnq = "$dir/QuoteDataPlainXML.plist";
#$fnq = "$dir/QuoteDataXML.plist";
}elsif($quotetitle eq "WRDQ"){
#WRDQ
$BibleVer = "Daily Quotes WRDQ";
#$dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/WRDQ\ iPhone\ Screen\ Shots";
$vindMatch = '2445.1260'; # verse index match
$imgMatch = 6199; # image name match
#$fn =  "$dir/ImageDataXML.plist";
#$fnq = "$dir/QuoteDataPlainXML.plist";
#$fnq = "$dir/QuoteDataXML.plist";
}else
{
    die "...Can't find match for quote parameters"
}
print "Processing $BibleVer";
# my $read = Data::Plist::Reader->new;
# contains image names

# my $fn =  "/Users/frankbraswell/Documents/Magic\ Briefcase/Xcode2015/Daily\ Quotes\ Perl\ Code\ -\ Data\ Files/Data\ Files\ KJV/ImageDataXML.plist";

# The plist files must be in the same folder with the files.
# my $fn =  "$dir/ImageDataXML.plist";

# contains the image quotes
# my $fnq = "/Users/frankbraswell/Documents/Magic\ Briefcase/Xcode2015/Daily\ Quotes\ Perl\ Code\ -\ Data\ Files/Data\ Files\ KJV/QuoteDataPlainXML.plist";

# find image order from index keys
# <key>E3-3.1107</key>
my $indvindMatch;
print "\nGet the ordering information from the keys\n";
open my($fhfn), $fn or die "... can't open $fn ...";
my @orderimages;
while(<$fhfn>)
{
    if(/<key>(.*)<\/key>/)
    {
        print "$1 ";
        push @orderimages, $1;
#        if($vindMatch == $1) # numeric
#        if($vindMatch eq $1) # alpha match
#        if($1 =~ /$vindMatch/) # regex match
#        {
#            $indvindMatch = (scalar @orderimages);
##            print "index of $vindMatch: $indvindMatch\n";
#            
#        }
    }
}
close $fhfn; # finished with file

###### This alpha sort is needed for Spurgeon #######
if($vindMatch =~ /^[ME]/)
{
    print "\nsort order images array for Spurgeon quotes";
    @orderimages = sort @orderimages;
}

for(my $i=0; $i< scalar @orderimages; $i++) 
{
        if($orderimages[$i] =~ /$vindMatch/) # regex match
        {
            $indvindMatch = $i+1;
#            print "index of $vindMatch: $indvindMatch\n";
            last;
        }
}

print "\nindex of vindMatch $vindMatch: $indvindMatch";
print "\nNumber of image keys: ".scalar @orderimages."";
# my $fnq = "$dir/QuoteDataPlainXML.plist";

my $htmlOut = $dir . '/aHTMLout.html';
open my($fhHTML), ">$htmlOut" or die "... can't open $htmlOut"; 

# Build sorted list of file names with screen shots
opendir my $dh, $dir or die "... can't open dir"; # work on image names
my $d;
my @files;
while ($d = readdir $dh)
{
#    if ($d =~ /^IMG_\d\d\d\d\.jpg/)
# can match either jpg or png files
# IMG_5608.jpg
# IMG_5608.1.jpg
# print "$d; ";
#    if ($d =~ /^IMG_\d\d\d\d\./)
    if ($d =~ /(^IMG_\d\d\d\d\.|^IMG_\d\d\d\d\.\d\.)(p|j)/i)
    {
#        print "$d; ";
        push @files, $d;
    }
}
@files = sort @files; # files must be in sorted order

print "\nnumber of valid image files in folder: ".scalar @files."\n";

# Get hash with index numbers and image names
my $p = getFile($fn);

my $numkeys = scalar keys $p;
print "number of keys: $numkeys\n";

# Get hash with index numbers and verse text
my $pq = getFile($fnq);

$numkeys = scalar keys $pq;
print "number of verse keys: $numkeys\n\n";

# ***** DEBUG ****
if(0)
{
    my $vindex = 145;
    print "verse index $vindex: $pq->{$vindex}\n";
    my $vtext;
    # ($vtext) = $pq->{$vindex} =~ /CDATA\[(.*)\]\]/;
    ($vtext) = $pq->{$vindex} =~ /CDATA\[(.*)\]\]/s;
    if( ! $vtext)
    {
        $vtext = "no match found";
    }
    print "verse text $vindex: $vtext\n\n";
}
# ***** DEBUG ****

# index 145, Psalm 62:1 corresponds to IMG_2709.jpg
# my $vindMatch = 145; # verse index match
print "verse index match at $vindMatch\n";
# locate file index for key matching images
# locate position in the file name array where the matching image is 
my $findMatch = 0; # file index match
for (my $i=0; $i< scalar @files; $i++ )
{
#    if ( $files[$i] =~ /2709/)
    if ( $files[$i] =~ /$imgMatch/)
    {
        print "found $files[$i] at index $i - file index match\n";
        $findMatch = $i;
        last; # exit loop
    }
}

# Build HTML file to check if images and verses match
print $fhHTML header_HTML($BibleVer);

# print $fhHTML table_HTML($files[$findMatch], $vindMatch);
# print $fhHTML table_HTML($files[$findMatch+1], $vindMatch+1);

# process in order of sorted files
for (my $i=0; $i< scalar @files; $i++ )
{
    # calculate verse index
#    print "ind $i: ".$numkeys%(($findMatch - $i)<0?($findMatch - $i)+$numkeys:($findMatch - $i))." ";
#    my $tmp = ($i - $findMatch)+$vindMatch;
    my $tmp = ($i - $findMatch)+$indvindMatch;
    my $verseind = $tmp;
    if ($tmp <= 0 )
    {
        $verseind = $tmp - 1 + $numkeys;
    } elsif ($tmp > $numkeys)
    {
        $verseind = $tmp + 1 - $numkeys;
    }
    
#    my $verseind = ($tmp<=0?$tmp-1+$numkeys:$tmp);
#    my $verseind = ($tmp<=0?$tmp-1+$numkeys:$tmp);
    $verseind = $numkeys if $tmp == 1; # special case because 1 is skipped in iPhone app!
    
#    print "ind $i: ".(($i - $findMatch)<0?($i - $findMatch)+$numkeys:($i - $findMatch))." ";
    print "ind $i: ".$verseind." ";
    print $fhHTML table_HTML($files[$i], $verseind);
    
}
print "\n";

print $fhHTML footer_HTML();

print "\n*********************************** end $0 program.***********************************\n";

sub getFile
{
    my $fn = shift;
    open my($fh), $fn or die "... can't open $fn";
    my $fstr = ''; # string to hold parsed string
    while(<$fh>)
    {
#        print $_ if /<!--/;
        if (! /<!--/)
        {
            $fstr .= $_;
        } 
    }
    my $data = parse_plist($fstr);
    my $p = $data->as_perl;
    return $p;
}

sub header_HTML
{
#______________________________________________________
# header
my $bv = shift;
return   <<EOT
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html>

<head>
    <title>$bv</title>
    
    <style type="text/css">
        a:link {
            COLOR: #00ffff;
        }
        
        a:visited {
            COLOR: #00ffff;
        }
        
        a:hover {
            COLOR: #FF0000;
        }
        
        a:active {
            COLOR: #00FF00;
        }
    </style>
</head>

<body bgcolor="#14285f">
EOT
;
}

#______________________________________________________
sub table_HTML
{
   my ($imageNum, $indNum) = @_;
   # Image screenshots have name in form: IMG_6199.jpg
   my $imgName = "IMG_$imageNum.jpg";
   $imgName = $imageNum;
   my $vtext;
#   my $rawtext = $pq->{$indNum};
   my $rawtext = $pq->{$orderimages[$indNum-1]};
   my $origimgname = $p->{$orderimages[$indNum-1]};
# ($vtext) = $pq->{$indNum} =~ /CDATA\[(.*)\]\]/;
# $rawtext =~ s/([^[:ascii:]]+)/unidecode($1)/ge; # translate non-ascii chars
($vtext) = $rawtext =~ /CDATA\[(.*)\]\]/s;
if( ! $vtext)
{
    $vtext = "verse not found!";
}

#my $BibleVer = "Psalm Daily Quotes KJV";
return  <<EOT
    <center>
        <!-- Source Number: $indNum -->

        <font size="4" color="white">$BibleVer<br></font>

        <table border="0" cellspacing="20" cellpadding="0">
            <tr align="left" valign="top">
            
                <td width="300" height="400">
                <!-- image goes here -->
                <!-- example:   <img src="autumn01i.jpg" width="300">   -->
                <!-- example: <img src="IMG_2709.jpg" width="300"> -->
                <img src="$imgName" width="300">
                
                </td>
                
                <td width="400">
                <font size="4" color="white">
                <!-- verse goes here -->
                Day Index: $indNum <br>
                Verse Index: $orderimages[$indNum-1] <br>
                Orig Image Name: $origimgname <br>
                iPhone Mockup Image Name: $imgName
                </font>
                <font size="3" color="white">
                <br><br>Quote Text: <br>$vtext
                <!-- example: 
                Psalm 62:1 Truly my soul waiteth upon God: from him cometh my salvation. 2 He only is my rock and my salvation; he is my defence; I shall not be greatly moved.
                -->
                </font>
                </td>
                
            </tr>
        </table>
        
    </center>
EOT
;
}

sub footer_HTML
{
#______________________________________________________
# footer
return
'</body>

</html>'
;
}