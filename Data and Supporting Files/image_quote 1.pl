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

print "\n*********************************** start image_quote.pl  program.***********************************\n";
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

opendir my $dh, $dir or die "... can't open dir"; # work on image names
my $d;
my @files;
while ($d = readdir $dh)
{
    if ($d =~ /^IMG_\d\d\d\d\.jpg/)
    {
        print "$d; ";
        push @files, $d;
    }
}

print "\nnumber of files: ".scalar @files."\n";
#open my($fh), $fn or die "... can't open $fn";
#my $fstr = ''; # string to hold parsed string
#while(<$fh>)
#{
#    print $_ if /<!--/;
#    if (! /<!--/)
#    {
#        $fstr .= $_;
#    } 
#}
## print Dumper($fstr);
#
#my $data = parse_plist($fstr);
# my $plist = $read->open_file($fn);
# my $data = parse_plist_fh( $fh );
# $data or die "... problems with data";

# $data = parse_plist_file( $fn );
# print "test key: 1, val: $data->{'1'}\n\n";

# print Dumper($data);

# my $p = $data->as_perl;

my $p = getFile($fn);

# print "test hash key: 1, val: $p->{'1'}\n\n";

# print Dumper($p);
my $numkeys = scalar keys $p;
print "number of keys: $numkeys\n";

#foreach my $k (sort {$a <=> $b} keys $p)
#{
#    print "k: $k, v: $p->{$k}| "
#}

my $pq = getFile($fnq);

$numkeys = scalar keys $pq;
print "number of verse keys: $numkeys\n\n";

my $vindex = 145;
my $vtext;
($vtext) = $pq->{$vindex} =~ /CDATA\[(.*)\]\]/;
print "verse text $vindex: $vtext\n";
# print "verse index 232: $pq->{232}";

print "\n*********************************** end image_quote.pl  program.***********************************\n";

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

sub table_HTML
{
#______________________________________________________
return
'    <center>
        <!-- Source Number: 4 -->

        <font size="6" color="ffffff">Psalm Daily Quotes KJV<br>
        
</font>

        <br>
        <br>

        <table border="0" cellspacing="20" cellpadding="0">
            <tr align="left" valign="top">
            
                <td width="300" height="400">
                <!-- image goes here -->
                <!-- example:   <img src="autumn01i.jpg" width="300">   -->
                
                <img src="IMG_2709.jpg" width="300">
                
                </td>
                
                <td width="300">
                <!-- verse goes here -->
                verse text 145: Psalm 62:1 Truly my soul waiteth upon God: from him cometh my salvation. 2 He only is my rock and my salvation; he is my defence; I shall not be greatly moved.

                </td>
                
            </tr>
        </table>
        
    </center>'
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