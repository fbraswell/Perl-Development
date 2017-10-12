#!/usr/bin/env perl -w
use strict;
use warnings;

# Confused between versions of Perl
# Installed JSON module for Perl but cannot load it, Can't locate JSON.pm in @INC
# https://stackoverflow.com/questions/41143638/installed-json-module-for-perl-but-cannot-load-it-cant-locate-json-pm-in-inc

# Octopart REST API Reference (V3)
# https://octopart.com/api/docs/v3/rest-api 

use LWP::Simple;
use Data::Dumper;
# use utf8;
binmode STDOUT, ":utf8"; # get rid of warnings about special characters

# use Scalar::Util 'blessed';
# use JSON qw( decode_json );
# http://www.tutorialspoint.com/json/json_perl_example.htm

# HTTP Error Codes
# 200 - Connected ok
# 429 - Hit rate limit!
# 500 Can't connect to Octopart - internet down?


use REST::Client;
use JSON;

print "\n*********************************** start program $0 program.***********************************\n";
# Part numbers go here

my $pnum = shift;
print "command line input: $pnum\n" if $pnum;

my $verbose = 0; # default 0 - Print everything = 1

# Location,Location 2,Quantity,Item

my $inStr = 
"Euler 229 Teaching Lab,,20,1N5235BTR
Euler 229 Teaching Lab,,10,1N5251B
Euler 229 Teaching Lab,,25,1N5819
Euler 229 Teaching Lab,,25,512-1N5231B
Euler 229 Teaching Lab,,50,833-1N4148W-TP
Euler 229 Teaching Lab,,25,BZX85B5V1-TR
Euler 229 Teaching Lab,,50,100F5T-YT-SRY-WH
Euler 229 Teaching Lab,,50,100F5T-YT-WH-WH
Euler 229 Teaching Lab,,25,551-0207F
Euler 229 Teaching Lab,,15,551-0407F
Euler 229 Teaching Lab,,20,LF-5WAEMBGMBC
Euler 229 Teaching Lab,,50,LTL2R3KRD-EM
Euler 229 Teaching Lab,,15,LTL2R3KYD-EM
Euler 229 Teaching Lab,,15,SLX-LX5093GD
Euler 229 Teaching Lab,,25,SSL-LX5093USBD
Euler 229 Teaching Lab,,3,10A2-B
Euler 229 Teaching Lab,,50,1N4001-TP
Euler 229 Teaching Lab,,50,1N4004-T
Euler 229 Teaching Lab,,10,SN74HC00N
Euler 229 Teaching Lab,,10,SN74HC02N
Euler 229 Teaching Lab,,10,SN74HC244N
Euler 229 Teaching Lab,,20,LM358AP
Euler 229 Teaching Lab,,15,CMB-6544PF
Euler 229 Teaching Lab,,2,BAT-HLD-001
Euler 229 Teaching Lab,,2,CR2032 Battery
Euler 229 Teaching Lab,,50,BCAP0050 P270 T01
Euler 229 Teaching Lab,,50,D103M29Z5UH6UJ5R
Euler 229 Teaching Lab,,50,ECA-1HM100I
Euler 229 Teaching Lab,,50,ESH105M050AC3AA
Euler 229 Teaching Lab,,50,ESH225M050AC3AA
Euler 229 Teaching Lab,,50,FK24X7R1H105K
Euler 229 Teaching Lab,,50,H102K25X7RL63J5R
Euler 229 Teaching Lab,,50,K102K15X7RF5TL2
Euler 229 Teaching Lab,,50,K104K15X7RF53H5
Euler 229 Teaching Lab,,20,RDE5C2A101J0M1H03A
Euler 229 Teaching Lab,,20,REA010M2CBK-0511P
Euler 229 Teaching Lab,,15,REA101M1EBK-0611P
Euler 229 Teaching Lab,,25,REA101M1HBK-0811P
Euler 229 Teaching Lab,,25,RGA4R7M1HBK-0511G
Euler 229 Teaching Lab,,,UPW1A222MHD
Euler 229 Teaching Lab,,20,USF1V150MDD
Euler 229 Teaching Lab,,10,UVR1E471MPD
Euler 229 Teaching Lab,,2,UVR1HR22MDD
Euler 229 Teaching Lab,,10,T73XW203KT20
Euler 229 Teaching Lab,,100,ERJ-6ENF1002V
Euler 229 Teaching Lab,,100,ERJ-6ENF1004V
Euler 229 Teaching Lab,,50,271-1.0M-RC
Euler 229 Teaching Lab,,50,271-100K-RC
Euler 229 Teaching Lab,,50,271-100-RC
Euler 229 Teaching Lab,,50,271-10K-RC
Euler 229 Teaching Lab,,50,271-10-RC
Euler 229 Teaching Lab,,50,271-1K-RC
Euler 229 Teaching Lab,,50,271-200K-RC
Euler 229 Teaching Lab,,50,271-20K-RC
Euler 229 Teaching Lab,,25,271-220-RC
Euler 229 Teaching Lab,,100,271-2K-RC
Euler 229 Teaching Lab,,100,271-47-RC
Euler 229 Teaching Lab,,25,271-49.9K-RC
Euler 229 Teaching Lab,,100,291-5.1-RC
Euler 229 Teaching Lab,,25,291-560-RC
Euler 229 Teaching Lab,,100,603-MFR-25FBF52-10R
Euler 229 Teaching Lab,,50,MF1/4DC1R00F
Euler 229 Teaching Lab,,50,MFR-25FRF52-20K
Euler 229 Teaching Lab,,50,2N3904TAR
Euler 229 Teaching Lab,,50,2N7000TA
Euler 229 Teaching Lab,,5,MJE3055TTU
Euler 229 Teaching Lab,,1,LM4040D25ILPR
Euler 229 Teaching Lab,,10,TL431CZ-AP
Euler 229 Teaching Lab,,10,LM78L05ACZX
Euler 229 Teaching Lab,,10,SPX1117M3-L-3-3/TR
Euler 229 Teaching Lab,,4,1-2199298-2
Euler 229 Teaching Lab,,20,1-2199298-3
Euler 229 Teaching Lab,,10,158-P02EK381V2-E
Euler 229 Teaching Lab,,6,AI-155
Euler 229 Teaching Lab,,10,PJ-102AH
Euler 229 Teaching Lab,,9,220ADC16
Euler 229 Teaching Lab,,50,TL1105FF100Q";

my $fname = 'inputdata.txt';
open my $fhandle, '<', $fname or die $!;
my @lines = (<$fhandle>); # grab entire file by lines into array
close($fhandle);
chomp(@lines); # get rid of last character, \n
# map {print "$_ "} @lines;
    # Number of part numbers (rows) input.
print "Length of lines: ", scalar @lines, "\n";
    # In the end the partCount should equal the number in @lines
my $partCount = 1; # Count each part looked up for output line

# Headers Example
# *Item Searched	Item	Description	MPN	Manufacturer	Vendor PN	Vendor					Category	Type	Location	Location 2	Quantity	Item	
# my @headersRow = qw (*Item Searched	Item	Description	MPN	Manufacturer	Vendor PN	Vendor					Category	Type	Location	Location 2	Quantity	Search);

    # First row must be the column names! - Headers
my @headersRow = split "\t", shift @lines;
print "Headers: ";
map {print "$_, "} @headersRow;
print "\n";

    # Need to know the index of each header name
my %headerNameIndex;
    # Put header names in as keys & indexes as values using slice
@headerNameIndex{@headersRow} = (0..$#headersRow);

foreach my $key (keys %headerNameIndex)
{
    print "header name: $key, index: $headerNameIndex{$key}\n";
}
# die "\nstop here\n";

my %partLoc = (); # Part location based on array above
my @partsOrder = (); # ordering of parts in the input spreadsheet file
# Organize input information according to the header labels
my $i = 0;
foreach (@lines)
{
    my @rowOfFields = split "\t", $_; # split line on tabs
    my $partx = $rowOfFields[1]; # *Item Searched field, index 1, second item
    @rowOfFields = map { 'naI' unless($_)} @rowOfFields; # place 'na' in all unknown fields
#    print "$i. ";
#    map {print "$_ => "} @rowOfFields; # debug print
#    print "\n";
    $i++;
        # Keep ordered list of part names
    push @partsOrder, $partx;
        # Put part information in partLoc hash
        # Store the address of @rowOfFields in hash location $partx
    $partLoc{$partx} = [@rowOfFields];
#    die "\nStop here!\n";
}
# die "\nStop here!\n";

# Get all the lines by splitting on newline
# @lines = split "\n", $inStr;
#    my %partLoc = (); # Part location based on array above
#    my @partsOrder = (); # ordering of parts in the input spreadsheet file

# Loop for processing each part
#foreach (@lines)
#{
#    # Get information already known about part
#    # location, location 2, quantity, and part number
#    my ($rm, $loc, $qty, $partx) = split ",", $_; # comma delimited
# #   my ($rm, $loc, $qty, $partx) = split "\t", $_; # tab delimited
#        # Make the part the key to an array of room, loc & qty
#    $rm = 'rm na' unless($rm);
#    $loc = 'loc na' unless($loc);
#    $qty = 'qty na' unless($qty);
#        # keep ordered list of the part names
#    push @partsOrder, $partx;
#        # Put array in hash indexed by part name
#    $partLoc{$partx} = [($rm, $loc, $qty)]; 
#}
    # test group of part names
my @mpn = qw( 1N5235BTR 1N5251B 1N5819 512-1N5231B 1N5231B);

@mpn = @partsOrder;
print "\n____Parts\n";
map { print "$_ "} @mpn;
print "\n____End Parts\n";

    # If a part is in the command line
@mpn =  ($pnum) if $pnum;

# ordering for the GS header
#    my @GSheaders = qw(Value    Search	Item	Description	MPN	
#                        Manufacturer  Vendor_PN	Vendor	Category	
#                        Type	Location	Location 2	Quantity);
                    
my @GSheaders = @headersRow;
    # init Hash for the values of each row of spreadsheet
my %GSvalues = ();
print "GSheader: " if $verbose;
    # Comma separated
# map {print $_, ', '} @GSheaders; 
    # Tab separated
map {print $_, "\t"} @GSheaders; 
print "\n";
    # May be used for categories/classes later
my @partClassArray = (
'ADAPTER','BAT','CAP','CBL','CON',
'DIODE','DISP','ELEC-MECH','HDR',
'HS','IC','IND','LED',
'MIC','MODULE','MOTOR','PCB',
'PROTOTYPING','PS','RES','SOCKET',
'SPKR','SW','TERM-BLCK','TRANS',
'WIRE','XFRMR','HWR',
);
    # Narrow down the list of seller to these vendors
my @sellerList = (
    'Newark', 'Digi-Key', 'Mouser', 'Arrow', 'element14',
);
print "Seller list: " if $verbose;
map {print $_, ", "} @sellerList if $verbose;
print "\n";
    # Init data structures 
my @Category_UIDS = ();
my @Categories = (); # Text 
my @Descriptions = ();
my @Short_Descriptions = ();
my $requestedPN;
my @Specifications = ();

# CURL Command
#	Franks-iMac:BerryGlobal frankbraswell$ curl -G http://octopart.com/api/v3/parts/match \
#	> -d queries="[{\"mpn\":\"2n7000\"}]" \
#	> -d apikey=4ed77e1e \
#	> -d pretty_print=true   \
#	> -d include[]=specs \
#	> -d include[]=descriptions
# my $octopart;
# $uri->query_form( $key1 => $val1, $key2 => $val2, ... )
    # Create Octopart object
my $octopart = REST::Client->new({
        host => 'http://octopart.com',
        'pretty_print' => 'true',
    });

foreach (@mpn)
{
    %GSvalues = (); # Init for next spreadsheet row
    print "\nRequest information on: $_\n" if $verbose;
    getPart($_); # Get the information
    sleep(0.5); # Avoid Octopart rate limit (in msec)
}
print "\n*********************************** end program $0  program.***********************************\n";

#____________________________________________________________

sub getPart
{
    my $part = shift;   # Get part name
    $octopart->GET('/api/v3/parts/match'
                    . '?' . 'apikey=4ed77e1e'
                    . '&' . "queries=[{\"mpn\":\"$part\"}]"
                    . '&' . 'include[]=descriptions'
                    . '&' . 'include[]=short_description'
                    . '&' . 'include[]=datasheets'
                    . '&' . 'include[]=category_uids'
                    . '&' . 'include[]=external_links'
                    . '&' . 'include[]=specs'
                    . '&' . 'include[]=imagesets'
                    . '&' . 'pretty_print=true'
                    );
    my $rc = $octopart->responseCode(); # Get response code
    print "\nHTTP request part responseCode: ", $rc, "\n"; # if $verbose;
    if($rc == 429) # Hit rate limit of 3 requests per second
    {
        print "Hit rate limit! \n";
        sleep(1);
    }

    my $json = JSON->new->allow_nonref;
    my $jsonDecode = $json->decode($octopart->responseContent());

    my $PartsMatchResponse = $jsonDecode; # top level information

#        PartsMatchResponse schema:
#        Property	 Description	         Example	                    Empty Value
#        request	 The original request	 <PartsMatchRequest object>	    n/a
#        results	 List of query results	 [<PartsMatchResult object>]	n/a
#        msec	     The server response 
#                    time in milliseconds	  234	                         n/a

    printResult("millisec: ", $PartsMatchResponse->{"msec"}) if $verbose;
    printResult("CLASS: ", $PartsMatchResponse->{"__class__"}) if $verbose;

    my $PartsMatchRequest = $PartsMatchResponse->{"request"};
    printResult("Request: ", $PartsMatchRequest->{"__class__"}) if $verbose;

    my $PartsMatchQuery = $PartsMatchRequest->{"queries"};
    printResult("Request for mpn: ", $PartsMatchQuery->[0]->{"mpn"}) if $verbose;
    printResult("Request for seller: ", $PartsMatchQuery->[0]->{"seller"}) if $verbose;
    printResult("Request for brand: ", $PartsMatchQuery->[0]->{"brand"}) if $verbose;

    my $PartsMatchResult = $PartsMatchResponse->{"results"};
    printResult("Results: ", $PartsMatchResult->[0]->{"__class__"}) if $verbose;
    printResult("Results hits: ", $PartsMatchResult->[0]->{"hits"}) if $verbose;
    printResult("Results error: ", $PartsMatchResult->[0]->{"error"}) if $verbose;

    # Results items is an arry of parts information
    my $Part = $PartsMatchResult->[0]->{"items"};
    printResult("Number in items (parts) array: ", scalar @{$Part}) if $verbose;

    if($Part)
    {
        for (my $i=0; $i < scalar @{$Part} ;$i++)
        {
            getItems($Part, $i);
        }
    }
#    foreach my $c (@Category_UIDS)
#    {
#        getCategory($json, $c);
#    }
    # only call getCategory once
    getCategory($json, $Category_UIDS[0]) if ($Category_UIDS[0]);
    $GSvalues{'Category'} =  $Categories[0] if $Categories[0];

#    foreach my $c (@Category_UIDS)
#    {
#        print "all cat uids: $c\n";
#    }
    #____________________________
#    print "\nNumber of Categories: ", scalar @Categories, "\n";
#    foreach my $c (@Categories)
#    {
#        print "all categories: $c\n";
#    }
    
        # Removing duplicate strings from an array
        # http://www.perlmonks.org/?node_id=604547
        # Hash slices explained
        # http://www.webquills.net/web-development/perl/perl-5-hash-slices-can-replace.html
    my (%hashput, @unique);
    unless(@Categories)
    {
        %hashput;
        @hashput{@Categories} = (); # use hash keys to get rid of dups
        @unique = sort keys %hashput; # unique sorted specs
        print "\nNumber of Sorted Categories: ", scalar @unique, "\n" if $verbose;
        map {print "all sorted categories: $_\n"} @unique if $verbose;
    }
    #____________________________
#    print "\nNumber of Specs: ", scalar @Specifications, "\n";
#    foreach my $s (@Specifications)
#    {
#        print "all spec: $s\n";
#    }
    unless(scalar @Specifications)
    {
        %hashput = ();
        @hashput{@Specifications} = ();
        @unique = sort keys %hashput;
        print "\nNumber of Sorted Specs: ", scalar @unique, "\n" if $verbose;
        map {print "all sorted spec: $_\n"} @unique if $verbose;
    }
    #____________________________
#    print "\nNumber of Desc: ", scalar @Descriptions, "\n";
#    foreach my $d (@Descriptions)
#    {
#        print "all desc: $d\n";
#    }
    unless(scalar @Descriptions)
    {
        %hashput = ();
        @hashput{@Descriptions} = ();
        @unique = sort keys %hashput;
        print "\nNumber of Sorted Desc: ", scalar @unique, "\n" if $verbose;
        map {print "all sorted desc: $_\n"} @unique if $verbose;
    }
    #____________________________
    
#    print "\nNumber of Short Desc: ", scalar @Short_Descriptions, "\n";
#    foreach my $d (@Short_Descriptions)
#    {
#        print "all short desc: $d\n";
#    }
    unless(scalar @Short_Descriptions)
    {
        %hashput = ();
        @hashput{@Short_Descriptions} = ();
        @unique = sort keys %hashput;
        print "\nNumber of Sorted Short Desc: ", scalar @unique, "\n" if $verbose;
        map {print "all sorted short desc: $_\n"} @unique if $verbose;
    }
    #____________________________
    
    # Fill in items from $inpStr - location, location 2, qty
    # Location	Location_2	Quantity
    unless (exists $partLoc{$part})
    {
        print "WARNING: This part: $part, doesn't exist in the hash.\n";
        return;
    }
    
#    my ($l, $l2, $q) = @{$partLoc{$part}};
#    $GSvalues{'Search'} = $part;
#    $GSvalues{'Location'} =  $l;
#    $GSvalues{'Location_2'} =  $l2;
#    $GSvalues{'Quantity'} =  $q;
    
    my @partRow = @{$partLoc{$part}};
    $GSvalues{'Search'} = $part;
    $GSvalues{'Location'} =  $partRow[$headerNameIndex{'Location'}];
    $GSvalues{'Location 2'} =  $partRow[$headerNameIndex{'Location 2'}];
    $GSvalues{'Quantity'} =  $partRow[$headerNameIndex{'Quantity'}];
    
    
    print "Spreadsheet Columns\n" if $verbose;

        # Print the spreadsheet columns with hash keys from header labels
    print "$partCount *==>";
    $partCount++;
        # Comma separated
 #   map {defined $GSvalues{$_}?print "$GSvalues{$_}, ": print "na, " } @GSheaders;
        # Tab separated
    map {defined $GSvalues{$_}?print "$GSvalues{$_}\t": print "naO\t" } @GSheaders;
    print "\n";
    
} # getPart

# Ask Octopart for category information
sub getCategory
{
    my ($json, $c) = @_;
    $octopart->GET("/api/v3/categories/$c"
                    . '?' . 'apikey=4ed77e1e');
    sleep(.5);
#    $octopart->GET('/api/v3/categories/get_multi'
#                    . '?' . 'apikey=4ed77e1e'
#                    . '&' . "queries=[{\"$c\"}]"
#                    );
    unless ($octopart->responseCode() ==200){
        print "HTTP request category responseCode: ", $octopart->responseCode(), " Category: ", $c, "\n";
    }

        my $Category = $json->decode($octopart->responseContent());
        push @Categories, $Category->{'name'};
        
        # Sample category data structure
 #       {"ancestor_names": ["Electronic Parts", "Passive Components", "Resistors"], "uid": "91ee5ce4a8204a29", "num_parts": 708565, "ancestor_uids": ["8a1e4714bb3951d9", "7542b8484461ae85", "5c6a91606d4187ad"], "children_uids": [], "__class__": "Category", "parent_uid": "5c6a91606d4187ad", "name": "Through-Hole Resistors"}      
} # sub getCategory

# Get item (parts) information
sub getItems
{
# ordering for the GS header
#           my @GSheaders = qw(Value	Item	Description	MPN	
#                    Manufacturer  Vendor_PN	Vendor	Category	
#                    Type	Location	Location_2	Quantity);	
    
    my $Part = shift;
    $_ = shift; # grab array index
    printResult("items $_ class: ", $Part->[$_]->{'__class__'}) if $verbose;
    printResult("items $_ mpn: ", $Part->[$_]->{'mpn'}) if $verbose;
    printResult("items $_ short desc: ", $Part->[$_]->{'short_description'}) if $verbose;
    push @Short_Descriptions, $Part->[$_]->{'short_description'};
    
    printResult("items $_ octopart url: ", $Part->[$_]->{'octopart_url'}) if $verbose;
    # Brand Object - brand
    my $Brand = $Part->[$_]->{'brand'};
    printResult("Brand Name: ", $Brand->{'name'}) if $verbose;
    printResult("Brand url: ", $Brand->{'homepage_url'}) if $verbose;
    printResult("Brand uid: ", $Brand->{'uid'}) if $verbose;
    # Manufacturer Object - manufacturer
    my $Manufacturer = $Part->[$_]->{'manufacturer'};
    printResult("Mfg display name: ", $Manufacturer->{'name'}) if $verbose;
    # Description Object - descriptions
    my $Description = $Part->[$_]->{'descriptions'};
    
    printResult("number of descriptions: ", scalar @$Description) if $verbose;
    map {printResult("    Description: ", $_->{'value'});
         push @Descriptions, $_->{'value'}; 
        } @$Description if $verbose;

    unless ($_) # use only the first mfg part values for now
    {
        %GSvalues = ( Item =>  $Part->[$_]->{'mpn'},
                        MPN => $Part->[$_]->{'mpn'},
                        Manufacturer => $Manufacturer->{'name'},
                        Description => $Part->[$_]->{'short_description'},
                    );
    } # unless ($_)
    
    my $Partspecs = $Part->[$_]->{'specs'};
    while ( my ($key, $val) = each (%$Partspecs))
    {
        my $v = $val->{'display_value'};
        print "       spec: ", $key, ": ", $v?$v:'NULL', "\n" if $verbose;
        my $tmp = sprintf "%s%s%s", $key , ": " , $v?$v:'NULL';
        push @Specifications, $tmp; # Collect specs
        if($key eq "mounting_style")
        {
            $GSvalues{'Type'} = $val->{'display_value'}; # TH or SMT
        }
    }
    
    my $Categories = $Part->[$_]->{'category_uids'};
    foreach my $c (@$Categories)
    {
 #       print " Category id: $c\n";
        push @Category_UIDS, $c;
    }   
    
    my $Offers = $Part->[$_]->{'offers'};
    foreach my $o (@$Offers)
    {      
        my $seller = $o->{'seller'}; # get seller object
        for (grep /$seller->{'name'}/i, @sellerList)
            {
              print "          Seller Matches: ", $_, "\n"  if $verbose;
            }
        print "           Seller: ", $seller->{'name'} if $verbose;
        print ", PartOffer sku: ", $o->{'sku'}, "\n" if $verbose;
        unless ($_) # use only the first mfg part values for now
        {
            $GSvalues{'Vendor'} = $seller->{'name'};
            $GSvalues{'Vendor_PN'} =  $o->{'sku'};
        } # unless ($_)
        
        my $prices = $o->{'prices'}->{'USD'};
        if($prices) # Are there prices in USD?
        {
            my $qty1 = $prices->[0]; # first element of the price array is the 
                                     # min quantity
            print "            quantity: ", $qty1->[0], ", price: ", $qty1->[1], "\n" if $verbose;
        } 
    }   # foreach my $o (@$Offers)
} # sub getItems

# Need to handle the case where result of query is a NULL object
sub printResult
{
    my ($str, $tmp) = @_;
    print $str, $tmp?$tmp:'NULL', "\n";
} # sub printResult

#    Class	Type1 for each Class								
#    ADAPTER	AC-MAINS								
#    BAT	LITHIUM								
#    CAP	AL	CERAMIC	FILM						
#    CBL	RIBBON-JUMPER								
#    CON	F:BARREL								
#    DIODE	RECTIFIER	SCHOTTKY	LASER	SIGNAL	ZENER				
#    DISP	OLED								
#    ELEC-MECH	BATT-HOLDER								
#    HDR	SHROUDED	SOCKET	UNSHROUDED						
#    HS	DISCRETE								
#    IC	LOGIC	MCU	OPAMP	REFERENCE	REGULATOR				
#    IND	FIXED								
#    LED	AMBR	YLW	GRN	IR	RED	WHT			
#    MIC	ELECTRET								
#    MODULE	ARDUINO								
#    MOTOR	LEGO-M								
#    PCB	LaserRcvr_Boost_board_v1.2	LaserRcvr_Output_board_v1.2	LedFob_r2d	Nano-CC-EL-ver-0.62	simple_ps_1v0			
#    PROTOTYPING	BREADBOARD WIRE KIT	SOLDERLESS BREADBOARD							
#    PS	AC								
#    RES	F (thin film)	TF (thick film)	CF (carbon film)	CdS	POT				
#    SOCKET	DIP								
#    SPKR	MAGNETIC								
#    SW	BIN-ENCODER	MOMENTARY	MULTI-DIRECTIONAL	SPDT					
#    TERM-BLCK	SCREW								
#    TRANS	BJT	MOSFET							
#    WIRE	MAGNET								
#    XFRMR	LF (line freq)	SMF (switch-mode freq)	RF						
#    HWR	STANDOFF
