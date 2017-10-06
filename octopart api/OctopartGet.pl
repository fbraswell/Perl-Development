#!/usr/bin/env perl -w
use strict;
use warnings;

# Confused between versions of Perl
# Installed JSON module for Perl but cannot load it, Can't locate JSON.pm in @INC
# https://stackoverflow.com/questions/41143638/installed-json-module-for-perl-but-cannot-load-it-cant-locate-json-pm-in-inc

use LWP::Simple;
use Data::Dumper;
# use utf8;
binmode STDOUT, ":utf8"; # get rid of warnings about special characters

# use Scalar::Util 'blessed';
# use JSON qw( decode_json );
# http://www.tutorialspoint.com/json/json_perl_example.htm

use REST::Client;
use JSON;

print "\n*********************************** start program $0 program.***********************************\n";
# Part numbers go here

my $pnum = shift;
print "command line input: $pnum\n";

my @mpn = (  );
if($pnum) # if argument found put it in @mpn
{
    push @mpn, $pnum;
}

my @partClassArray = (
'ADAPTER','BAT','CAP','CBL','CON',
'DIODE','DISP','ELEC-MECH','HDR',
'HS','IC','IND','LED',
'MIC','MODULE','MOTOR','PCB',
'PROTOTYPING','PS','RES','SOCKET',
'SPKR','SW','TERM-BLCK','TRANS',
'WIRE','XFRMR','HWR',
);
my @sellerList = (
    'Newark',
    'Digi-Key',
    'Mouser', 
    'Arrow',
    'element14',
);
for (@sellerList)
{
  print "Seller list: ", $_, "\n";;
}
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

my $octopart = REST::Client->new({
	host => 'http://octopart.com',
	'pretty_print' => 'true',
#	'apikey' => "4ed77e1e",
#	queries => "[{\"mpn\":\"2n7000\"}]", 

});

foreach my $p (@mpn)
{
    getPart($p);
}

sub getPart
{
    my $part = shift;

    $octopart->buildQuery({'pretty_print'=>'true'});
    # $octopart->GET('/api/v3/parts/match?apikey=4ed77e1e&queries=[{"mpn":"2n7000"}]&pretty_print=true');
    # $octopart->GET("/api/v3/parts/match?apikey=4ed77e1e&queries=[{\"mpn\":\"$part\"}]");
    $octopart->GET('/api/v3/parts/match'
                    . '?' . 'apikey=4ed77e1e'
                    . '&' . "queries=[{\"mpn\":\"$part\"}]"
                    . '&' . 'include[]=descriptions'
                    . '&' . 'include[]=short_description'
                    . '&' . 'include[]=datasheets'
                    . '&' . 'include[]=category_uids'
                    . '&' . 'include[]=external_links'
                    . '&' . 'include[]=specs'
                    . '&' . 'pretty_print=true'
                    );
    # $octopart->GET('/api/v3/parts/match', {'apikey' => '4ed77e1e'});
    # $octopart->request('GET', 'http://octopart.com/api/v3/parts/match', 'request body content');
    print "\nHTTP request responseCode: ", $octopart->responseCode(), "\n";
    # print $octopart->responseCode();
     #   print "\nStart responseContent\n";
     #   print $octopart->responseContent();
     #   print "\nEnd responseContent\n";

    my $json = JSON->new->allow_nonref;
    my $jsonDecode = $json->decode($octopart->responseContent());

    my $PartsMatchResponse = $jsonDecode; # top level information

    #    print "millisec: ", $jsonDecode->{"msec"}, "\n";
    #    print "CLASS: ", $jsonDecode->{"__class__"}, "\n";

    # print "millisec: ", $PartsMatchResponse->{"msec"}, "\n";
    printResult("millisec: ", $PartsMatchResponse->{"msec"});
    # print "CLASS: ", $PartsMatchResponse->{"__class__"}, "\n";
    printResult("CLASS: ", $PartsMatchResponse->{"__class__"});

    my $PartsMatchRequest = $PartsMatchResponse->{"request"};
    # print "Request: ", $PartsMatchResponse->{"request"}->{"__class__"}, "\n";
    printResult("Request: ", $PartsMatchRequest->{"__class__"});

    my $PartsMatchQuery = $PartsMatchRequest->{"queries"};

    # print "Request for mpn: ", $PartsMatchResponse->{"request"}->{"queries"}[0]->{"mpn"}, "\n";
    printResult("Request for mpn: ", $PartsMatchQuery->[0]->{"mpn"});
    printResult("Request for seller: ", $PartsMatchQuery->[0]->{"seller"});
    printResult("Request for brand: ", $PartsMatchQuery->[0]->{"brand"});

    my $PartsMatchResult = $PartsMatchResponse->{"results"};
    # print "Results: ", $PartsMatchResponse->{"results"}[0]->{"__class__"}, "\n";
    printResult("Results: ", $PartsMatchResult->[0]->{"__class__"});
    printResult("Results hits: ", $PartsMatchResult->[0]->{"hits"});
    printResult("Results error: ", $PartsMatchResult->[0]->{"error"});

    # Results items is an arry of parts information
    my $Part = $PartsMatchResult->[0]->{"items"};
    printResult("Number in items (parts) array: ", scalar @{$Part});

    for (my $i=0; $i < scalar @{$Part} ;$i++)
    {
        getItems($Part, $i);
    }

    #        "category_uids": [
    #            "91ee5ce4a8204a29",
    #            "7542b8484461ae85",
    #            "5c6a91606d4187ad"]
    # print "\nGet Category\n";
    #    getCategory('91ee5ce4a8204a29');
    #    getCategory('7542b8484461ae85');
    #    getCategory('5c6a91606d4187ad');

    foreach my $c (@Category_UIDS)
    {
        getCategory($json, $c);
    }

    foreach my $c (@Category_UIDS)
    {
        print "all cat uids: $c\n";
    }
    foreach my $c (@Categories)
    {
        print "all categories: $c\n";
    }
    # print Dumper(@Category_UIDS);
    foreach my $s (@Specifications)
    {
        print "all spec: $s\n";
    }
    foreach my $d (@Descriptions)
    {
        print "all desc: $d\n";
    }
} # getPart

print "\n*********************************** end program $0  program.***********************************\n";

# Ask Octopart for category information
sub getCategory
{
#    my ($json, $c) = shift;
    my ($json, $c) = @_;
    $octopart->GET("/api/v3/categories/$c"
                    . '?' . 'apikey=4ed77e1e');
    unless ($octopart->responseCode() ==200){
    print "HTTP request responseCode: ", $octopart->responseCode(), "\n";
    }
    # print $octopart->responseCode();
#        print "\nStart category\n";
#        print $octopart->responseContent();
        my $Category = $json->decode($octopart->responseContent());
#        print "\n";
#        print "Category name: ", $Category->{'name'}, "\n";
        push @Categories, $Category->{'name'};
#        print "\nEnd category\n";
        
        # Sample category data structure
 #       {"ancestor_names": ["Electronic Parts", "Passive Components", "Resistors"], "uid": "91ee5ce4a8204a29", "num_parts": 708565, "ancestor_uids": ["8a1e4714bb3951d9", "7542b8484461ae85", "5c6a91606d4187ad"], "children_uids": [], "__class__": "Category", "parent_uid": "5c6a91606d4187ad", "name": "Through-Hole Resistors"}      
} # sub getCategory

# Get item (parts) information
sub getItems
{
    my $Part = shift;
    $_ = shift; # grab array index
    printResult("items $_ class: ", $Part->[$_]->{'__class__'});
    printResult("items $_ mpn: ", $Part->[$_]->{'mpn'});
    printResult("items $_ short desc: ", $Part->[$_]->{'short_description'});
    printResult("items $_ octopart url: ", $Part->[$_]->{'octopart_url'});
    # Brand Object - brand
    my $Brand = $Part->[$_]->{'brand'};
    printResult("Brand Name: ", $Brand->{'name'});
    printResult("Brand url: ", $Brand->{'homepage_url'});
    printResult("Brand uid: ", $Brand->{'uid'});
    # Manufacturer Object - manufacturer
    my $Manufacturer = $Part->[$_]->{'manufacturer'};
    printResult("Mfg display name: ", $Manufacturer->{'name'});
    # Description Object - descriptions
    my $Description = $Part->[$_]->{'descriptions'};
    printResult("number of descriptions: ", scalar @$Description);

    foreach my $d (@$Description)
    {
        printResult("    Description: ", $d->{'value'});
        push @Descriptions, $d->{'value'};
#        foreach my $p (@partClassArray){
#            if($d->{'value'} =~ /$p/i)
#            {
#                print "     FOUND $p!\n";
#            }
#        }       
    } # foreach my $d (@$Description)
    
    my $Partspecs = $Part->[$_]->{'specs'};
    while ( my ($key, $val) = each (%$Partspecs))
    {
        my $v = $val->{'display_value'};
        print "       spec: ", $key, ": ", $v?$v:'NULL', "\n";
        my $tmp = sprintf "%s%s%s", $key , ": " , $v?$v:'NULL';
 #       print $tmp, "\n";
        push @Specifications, $tmp; # Collect specs
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
#        my @matches = grep /$seller->{'name'}/, @sellerList;
#       for (@matches)
        for (grep /$seller->{'name'}/i, @sellerList)
            {
              print "          Seller Matches: ", $_, "\n";;
            }
#        if(scalar @matches)
#        {
#            print "   --- found seller in list!\n";
#        }
        
        print "           Seller: ", $seller->{'name'};
        print ", PartOffer sku: ", $o->{'sku'}, "\n";
        my $prices = $o->{'prices'}->{'USD'};
        if($prices) # Are there prices in USD?
        {
            my $qty1 = $prices->[0]; # first element of the price array is the 
                                     # min quantity
            print "            quantity: ", $qty1->[0], ", price: ", $qty1->[1], "\n";
        } 
    }
    
    
    
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
#


