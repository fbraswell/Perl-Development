#!/usr/bin/perl -w

# usage
# image_quote.pl

use strict;
use warnings;
# use Data::Plist::Reader;
use Mac::PropertyList qw( :all );
use Data::Dumper qw(Dumper);
use Try::Tiny;
# use POSIX;

# print "\n*********************************** start image_quote.pl  program.***********************************\n";

print "\n*********************************** start $0 program.***********************************\n";
$| = 1; # flush after every write
$\ = ""; # output record separator

# verse text 1: Psalm 3:8 Salvation belongeth unto the LORD: thy blessing is upon thy people.

# verse text 145: Psalm 62:1 Truly my soul waiteth upon God: from him cometh my salvation. 2 He only is my rock and my salvation; he is my defence; I shall not be greatly moved.

# index 145, Psalm 62:1 corresponds to IMG_2709.jpg

# my $read = Data::Plist::Reader->new;
# contains image names
my $fn =  "/Users/frankbraswell/Documents/Magic\ Briefcase/Xcode2015/Daily\ Quotes\ Perl\ Code\ -\ Data\ Files/Data\ Files\ KJV/ImageDataXML.plist";

# contains the image quotes
my $fnq = "/Users/frankbraswell/Documents/Magic\ Briefcase/Xcode2015/Daily\ Quotes\ Perl\ Code\ -\ Data\ Files/Data\ Files\ KJV/QuoteDataPlainXML.plist";

my $dir = "/Volumes/SOM128Gb/Daily\ Quotes\ iTunes\ Info/KJV\ iPhone\ Screen\ Shots/KJV\ images\ all";

my $htmlOut = $dir . '/aHTMLout.html';
open my($fhHTML), ">$htmlOut" or die "... can't open $htmlOut"; 

# Build sorted list of file names with screen shots
opendir my $dh, $dir or die "... can't open dir"; # work on image names
my $d;
my @files;
while ($d = readdir $dh)
{
    if ($d =~ /^IMG_\d\d\d\d\.jpg/)
    {
#        print "$d; ";
        push @files, $d;
    }
}

print "\nnumber of valid image files in folder: ".scalar @files."\n";

# Get hash with index numbers and image names
my $p = getFile($fn);

my $numkeys = scalar keys $p;
print "number of keys: $numkeys\n";

# Get has with index numbers and verse text
my $pq = getFile($fnq);

$numkeys = scalar keys $pq;
print "number of verse keys: $numkeys\n\n";

my $vindex = 145;
my $vtext;
($vtext) = $pq->{$vindex} =~ /CDATA\[(.*)\]\]/;
print "verse text $vindex: $vtext\n";
# print "verse index 232: $pq->{232}";

# index 145, Psalm 62:1 corresponds to IMG_2709.jpg
my $vindMatch = 145; # verse index match
print "verse index match at $vindMatch\n";
# locate file index for key matching images
my $findMatch = 0; # file index match
for (my $i=0; $i< scalar @files; $i++ )
{
    if ( $files[$i] =~ /2709/)
    {
        print "found $files[$i] at index $i - file index match\n";
        $findMatch = $i;
        last; # exit loop
    }
}

# Build HTML file to check if images and verses match
print $fhHTML header_HTML();

# print $fhHTML table_HTML($files[$findMatch], $vindMatch);
# print $fhHTML table_HTML($files[$findMatch+1], $vindMatch+1);

# process in order of sorted files
for (my $i=0; $i< scalar @files; $i++ )
{
    # calculate verse index
#    print "ind $i: ".$numkeys%(($findMatch - $i)<0?($findMatch - $i)+$numkeys:($findMatch - $i))." ";
    my $tmp = ($i - $findMatch)+$vindMatch;
#    my $verseind = ($tmp<=0?$tmp-1+$numkeys:$tmp);
    my $verseind = ($tmp<=0?$tmp-1+$numkeys:$tmp);
    $verseind = $numkeys if $tmp == 1; # special case?
    
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
return 
'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html>

<head>
    <title>Psalm Daily Quotes KJV</title>
    
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

<body bgcolor="#14285f">'
;
}

#______________________________________________________
sub table_HTML
{
   my ($imageNum, $indNum) = @_;
   my $imgName = "IMG_$imageNum.jpg";
   $imgName = $imageNum;
   my $vtext;
($vtext) = $pq->{$indNum} =~ /CDATA\[(.*)\]\]/;
my $BibleVer = "Psalm Daily Quotes KJV";
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
                
                <td width="300">
                <font size="4" color="white">
                <!-- verse goes here -->
                Verse Index $indNum <br>Image Name: $imgName
                </font>
                <font size="3" color="white">
                <br><br>$vtext
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