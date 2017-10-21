#!/usr/bin/env perl -w
use strict;
use warnings;

# This program imports tab delimited data  in file 'inputdata.txt' 
# which includes manufacturers part numbers.
# It looks up the part information on Octopart and populates the information for each part
# in a tab delimited output file.

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

#    HTTP Status	Likely cause
#    200            OK	Your request was completed successfully
#    400            Bad Request	Your request is missing an 'apikey' argument
#    403            Forbidden	Your apikey is invalid
#    404            Not Found	The resource you are accessing doesn't exist
#    429            Too Many Requests	You have been blocked by the rate limiter
#    500            Internal Server Error	Something went wrong server-side and we've 
#                   been notified about the problem. In many cases, there was a problem 
#                   with your request which wasn't handled properly by the server.
#    502            Bad Gateway	Our app servers have crashed. This error happens extremely rarely. 
#                   If you encounter it repeatedly please notify us ASAP.
#    503            Service Unavailable	The service is down for maintenance and will be restored ASAP


use REST::Client;
use JSON;
use Time::HiRes qw/gettimeofday/;

my $verbose = 0; # default 0 - Print everything = 1
my $tod = gettimeofday; # Time of Day
my $prev_tod = gettimeofday(); # previous Time of Day
my $ratelimit = 0.5; # rate which calls can be made in seconds


print "\n*********************************** start program $0 program.***********************************\n";
# Part numbers go here

my $pnum = shift;
print "command line input: $pnum\n" if $pnum;

my $fname = 'inputdata.txt';
open my $fhandle, '<', $fname or die $!;
my @lines = (<$fhandle>); # grab entire file by lines into array
close($fhandle);
chomp(@lines); # get rid of last character, \n
# map {print "$_ "} @lines;
    # Number of part numbers (rows) input.
print "Length of lines: ", scalar @lines, "\n";
    # In the end the partCount should equal the number in @lines
my $partCount = 1; # init - Count each part looked up for output line

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

    # test group of part names
my @mpn = qw( 1N5235BTR 1N5251B 1N5819 512-1N5231B 1N5231B);

@mpn = @partsOrder;
print "\n____Parts found: ", scalar @mpn ,"\n";
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
my %Category_UIDS_hash = (); # no dups in hash keys
my @Categories = (); # Text 
my %Categories_hash = (); # Text  # no dups in hash keys 
my @Descriptions = ();
my %Descriptions_hash = (); # no dups in hash keys
my @Short_Descriptions = ();
my %Short_Descriptions_hash = (); # no dups in hash keys
my @Specifications = ();
my %Specifications_hash = (); # no dups in hash keys
my $requestedPN;


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
    @Category_UIDS = ();
    %Category_UIDS_hash = (); # no dups in hash keys
    my @Categories = (); # Text 
    %Categories_hash = (); # Text  # no dups in hash keys 
    @Descriptions = ();
    %Descriptions_hash = (); # no dups in hash keys
    @Short_Descriptions = ();
    %Short_Descriptions_hash = (); # no dups in hash keys
    @Specifications = ();
    %Specifications_hash = (); # no dups in hash keys
    %GSvalues = (); # Init for next spreadsheet row
    print "\nRequest information on: $_\n" if $verbose;
    getPart($_); # Get the information
#    sleep(0.5); # Avoid Octopart rate limit (in msec)
}
print "\n*********************************** end program $0  program.***********************************\n";

#____________________________________________________________

sub getPart
{
    my $part = shift;   # Get part name
#    sleep(0.95); # Avoid Octopart rate limit (in msec) - no effect
#    $tod = gettimeofday();
#    print "---Time elapsed in msec: ", $tod - $prev_tod, "\n";
#    $prev_tod = $tod;
    
    $tod = gettimeofday();   
    my $elapsedtime = $tod - $prev_tod;

# print "---Category Time elapsed in msec: ", $elapsedtime, "\n";
    if ($elapsedtime < $ratelimit) # check for rate limit violation
    {
        # Need to sleep for a moment to avoid rate limit
        #    sleep(0.5);
        # select(undef,undef,undef, 0.5); # sleep - can be for less than 1 sec
        select(undef,undef,undef, $ratelimit - $elapsedtime); # sleep - can be for less than 1 sec
    }
#    print "---Part Time elapsed in sec: ", gettimeofday() - $prev_tod, "\n";
    $prev_tod = $tod;
    
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
    unless ($rc == 200)
    {
        print "*________ HTTP request part responseCode: ", $rc; # if $verbose;
        if($rc == 429) # Hit rate limit of 3 requests per second
        {
            print " Hit rate limit!";
 #           sleep(1);
        }
        print "\n";
    }
    
    my $json = JSON->new->allow_nonref;
    my $jsonDecode = $json->decode($octopart->responseContent());

    my $PartsMatchResponse = $jsonDecode; # top level information

#SCHEMA        PartsMatchResponse schema:
#SCHEMA        Property	 Description	         Example	                    Empty Value
#SCHEMA        request	 The original request	 <PartsMatchRequest object>	    n/a
#SCHEMA        results	 List of query results	 [<PartsMatchResult object>]	n/a
#SCHEMA        msec	     The server response 
#SCHEMA                  time in milliseconds	 234	                        n/a

#    unless ($PartsMatchResponse->{"msec"})
#    {
#        sleep(.5); # If "msec" is NULL we hit rate limit
#    }
    printResult("millisec: ", $PartsMatchResponse->{"msec"}) if $verbose;
    printResult("CLASS: ", $PartsMatchResponse->{"__class__"}) if $verbose;

    my $PartsMatchRequest = $PartsMatchResponse->{"request"};
    printResult("Request: ", $PartsMatchRequest->{"__class__"}) if $verbose;


#SCHEMA        PartsMatchRequest schema:
#SCHEMA        Property	    Description	                     Example	                    Empty Value
#SCHEMA        queries	    List of queries	                 [<PartsMatchQuery object>]	[]
#SCHEMA        exact_only	Match on non-alphanumeric 
#SCHEMA                     characters in part numbers	     true	                        false

    my $PartsMatchQuery = $PartsMatchRequest->{"queries"};
    
#SCHEMA        PartsMatchQuery schema:
#SCHEMA        Property	    Description	                    Example	                Empty Value
#SCHEMA        q	        Free-form keyword query	        "TI SN74S74N"	        ""
#SCHEMA        mpn	        MPN search filter (See notes: 
#SCHEMA                     Part Number Filters)	        "SN74S74N"	            null
#SCHEMA        brand	    Brand search filter	            "Texas Instruments"	    null
#SCHEMA        sku	        SKU search filter (See notes: 
#SCHEMA                     Part Number Filters)	        "67K1122"	            null
#SCHEMA        seller	    Seller search filter	        "Newark"	            null
#SCHEMA        mpn_or_sku	MPN or SKU search filter (See 
#SCHEMA                     notes: Part Number Filters)	    "SN74S74N"	            null
#SCHEMA        start	    Ordinal position of first 
#SCHEMA                     returned item	                0	                    0
#SCHEMA        limit	    Maximum number of items 
#SCHEMA                     to return	                    20	                    3
#SCHEMA        reference	Arbitrary string for 
#SCHEMA                     identifying results	            "line1"	                null
    
    printResult("Request for mpn: ", $PartsMatchQuery->[0]->{"mpn"}) if $verbose;
    printResult("Request for seller: ", $PartsMatchQuery->[0]->{"seller"}) if $verbose;
    printResult("Request for brand: ", $PartsMatchQuery->[0]->{"brand"}) if $verbose;

#SCHEMA        PartsMatchResponse schema:
#SCHEMA        Property	     Description	            Example	                       Empty Value
#SCHEMA        request	     The original request	   <PartsMatchRequest object>	   n/a
#SCHEMA        results	     List of query results	   [<PartsMatchResult object>]	   n/a
#SCHEMA        msec	         The server response 
#SCHEMA                      time in milliseconds	   234	                           n/a

    my $PartsMatchResult = $PartsMatchResponse->{"results"};
    
#SCHEMA        PartsMatchResult schema:
#SCHEMA        Property	    Description	                Example	                    Empty Value
#SCHEMA        items	    List of matched parts	    [<Part object>]	            []
#SCHEMA        hits	        Total number of matched 
#SCHEMA                     items	                    2	                        null
#SCHEMA        reference	Reference string specified 
#SCHEMA                     in query	                "line1"	                    null
#SCHEMA        error	    Error message 
#SCHEMA                     (if applicable)	            "Missing search filters"	null
    
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

    if(@Category_UIDS) # get rid of dup UIDS to cut down on category http calls
    {
        @Category_UIDS_hash{@Category_UIDS} = ();
        print "\nNumber of Sorted hash Category_UIDS: ", scalar keys %Category_UIDS_hash, "\n" if $verbose;
        map {print "all sorted hash category uids: $_\n"} sort keys %Category_UIDS_hash if $verbose;
        @Category_UIDS = sort keys %Category_UIDS_hash;
    }
    
#    foreach my $cate (@Category_UIDS)
#    {
#        getCategory($json, $cate)
#    }
    
    map {getCategory($json, $_)} @Category_UIDS;

    # only call getCategory once
    getCategory($json, $Category_UIDS[0]) if ($Category_UIDS[0]);
    $GSvalues{'Category'} =  $Categories[0] if $Categories[0];

    #____________________________    
        # Removing duplicate strings from an array
        # http://www.perlmonks.org/?node_id=604547
        # Hash slices explained
        # http://www.webquills.net/web-development/perl/perl-5-hash-slices-can-replace.html

    if (@Categories) # print information if there are @Categories
    {
        # Create hash to get rid of dups
        @Categories_hash{@Categories} = (); # use hash keys to get rid of dups
        print "\nNumber of Sorted hash Categories: ", scalar keys %Categories_hash, "\n" if $verbose;
        map {print "all sorted hash categories: $_\n"} sort keys %Categories_hash; # if $verbose;
    }
    #____________________________
    if (scalar @Specifications) # print information if there are @Specifications
    {
        # Create hash to get rid of dups
        @Specifications_hash{@Specifications} = ();
        print "\nNumber of Sorted hash Specs: ", scalar keys %Specifications_hash, "\n" if $verbose;
        map {print "all sorted hash spec: $_\n"} sort keys %Specifications_hash if $verbose;
    }
    #____________________________
    if (scalar @Descriptions) # print information if there are @Descriptions
    {
        # Create hash to get rid of dups
        @Descriptions_hash{@Descriptions} = ();
        print "\nNumber of Sorted hash Desc: ", scalar keys %Descriptions_hash, "\n" if $verbose;
        map {print "all sorted hash desc: $_\n"} sort keys %Descriptions_hash if $verbose;
    }
    #____________________________
    if (scalar @Short_Descriptions) # print information if there are @Short_Descriptions
    {
        # Create hash to get rid of dups
        @Short_Descriptions_hash{@Short_Descriptions} = ();
        print "\nNumber of Sorted Short hash Desc: ", scalar keys %Short_Descriptions_hash, "\n" if $verbose;
        map {print "all sorted hash short desc: $_\n" if $_} sort keys %Short_Descriptions_hash if $verbose;
    }
    #____________________________
    
    # Fill in items from $inpStr - location, location 2, qty
    # Location	Location_2	Quantity
    unless (exists $partLoc{$part})
    {
        print "WARNING: This part: $part, doesn't exist in the hash.\n";
        return;
    }
    
    # Fill in items that are already known for the part, 
    # such as location and quantity, in their respective columns
    my @partRow = @{$partLoc{$part}};
#    $GSvalues{'Search'} = $part;
#    $GSvalues{'*Item Searched'} = $part;
#    $GSvalues{'Item'} =  $partRow[$headerNameIndex{'Item'}];
#    $GSvalues{'Location'} =  $partRow[$headerNameIndex{'Location'}];
#    $GSvalues{'Location 2'} =  $partRow[$headerNameIndex{'Location 2'}];
#    $GSvalues{'Quantity'} =  $partRow[$headerNameIndex{'Quantity'}];
    
    %GSvalues = (
        Search => $part,
        '*Item Searched' => $part,
        Item => $partRow[$headerNameIndex{'Item'}],
        Location => $partRow[$headerNameIndex{'Location'}],
        'Location 2' => $partRow[$headerNameIndex{'Location 2'}],
        Quantity => $partRow[$headerNameIndex{'Quantity'}],
    );
      
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
#    sleep(0.5);
#    select(undef,undef,undef, 0.5); # sleep - can be for less than 1 sec
    $tod = gettimeofday();   
    my $elapsedtime = $tod - $prev_tod;

# print "---Category Time elapsed in msec: ", $elapsedtime, "\n";
    if ($elapsedtime < $ratelimit) # check for rate limit violation
    {
        # Need to sleep for a moment to avoid rate limit
        #    sleep(0.5);
        # select(undef,undef,undef, 0.5); # sleep - can be for less than 1 sec
        select(undef,undef,undef, $ratelimit - $elapsedtime); # sleep - can be for less than 1 sec
    }
#    print "---Category Time elapsed in sec: ", gettimeofday() - $prev_tod, "\n";
    $prev_tod = $tod;
    $octopart->GET("/api/v3/categories/$c"
                    . '?' . 'apikey=4ed77e1e');
                    
# Eventually try multi get categories                    
# GET /categories/get_multi - Fetch multiple categories simultaneously

    my $rc = $octopart->responseCode();
    unless ($rc == 200){
        print "*======== HTTP request category responseCode: ", $octopart->responseCode(), " Category: ", $c;
        if($rc == 429) # Hit rate limit of 3 requests per second
        {
            print " Hit rate limit!";
#            sleep(1);
        }
        print "\n";
    }

        my $Category = $json->decode($octopart->responseContent());
 #       print "category UID: $c, name: ", $Category->{'name'}, "\n";
        push @Categories, $Category->{'name'} if $Category->{'name'};
        
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
    
#SCHEMA        Part schema:

#SCHEMA        Property	            Description	                                Example	                         Empty Value
#SCHEMA        uid	                64-bit unique identifier	                "e7392c64ca2538fe"	             n/a
#SCHEMA        mpn	                The manufacturer part number	            "SN74S74N"	                     n/a
#SCHEMA        manufacturer	        Object representing the manufacturer	    <Manufacturer object>	         n/a
#SCHEMA        brand	            Object representing the brand	            <Brand object>	n/a
#SCHEMA        octopart_url	        The url of the Octopart part detail page	"http://octopart.com/XXXX"	     n/a
#SCHEMA        external_links	    Hidden by default (See Include Directives)	<ExternalLinks object>	         n/a

#SCHEMA        Pricing and Availability
#SCHEMA        offers	            List of offer objects	                    [<PartOffer object>]	         []
#SCHEMA        broker_listings	    Hidden by default (See Include Directives)	<BrokerListing object>	         []

#SCHEMA        Descriptions and Images
#SCHEMA        short_description	Hidden by default (See Include Directives)	"CAP THIN FILM 0.3PF 16V 01005"	 null
#SCHEMA        descriptions	        Hidden by default (See Include Directives)	[<Description object>]	         []
#SCHEMA        imagesets	        Hidden by default (See Include Directives)	[<ImageSet object>]	             []

#SCHEMA        Documents and Files
#SCHEMA        datasheets	        Hidden by default (See Include Directives)	[<Datasheet object>]	         []
#SCHEMA        compliance_documents	Hidden by default (See Include Directives)	[<ComplianceDocument object>]	 []
#SCHEMA        reference_designs	Hidden by default (See Include Directives)	[<ReferenceDesign object>]	     []
#SCHEMA        cad_models	        Hidden by default (See Include Directives)	[<CADModel object>]	             []

#SCHEMA        Technical Specs
#SCHEMA        specs	            Hidden by default (See Include Directives)	See notes: Part.specs	         {}
#SCHEMA        category_uids	    Hidden by default (See Include Directives)	["8ffd42f7bed8543a", 
#SCHEMA                                                                          "7a48b7424b6aa18f"]	         []
    
    printResult("items $_ class: ", $Part->[$_]->{'__class__'}) if $verbose;
    printResult("items $_ mpn: ", $Part->[$_]->{'mpn'}) if $verbose;
    printResult("items $_ short desc: ", $Part->[$_]->{'short_description'}) if $verbose;
    push @Short_Descriptions, $Part->[$_]->{'short_description'} if $Part->[$_]->{'short_description'};
    
    printResult("items $_ octopart url: ", $Part->[$_]->{'octopart_url'}) if $verbose;
    
#SCHEMA        Brand schema:
#SCHEMA        Property	        Description	                Example	                Empty Value
#SCHEMA        uid	            64-bit unique identifier	"3c8cfd861098eb4b"	    n/a
#SCHEMA        name	            The brand's display name	"Texas Instruments"	    n/a
#SCHEMA        homepage_url	    The brand's homepage url	"http://example.com"	null
    
    # Brand Object - brand
    my $Brand = $Part->[$_]->{'brand'};
    printResult("Brand Name: ", $Brand->{'name'}) if $verbose;
    printResult("Brand url: ", $Brand->{'homepage_url'}) if $verbose;
    printResult("Brand uid: ", $Brand->{'uid'}) if $verbose;
    
#SCHEMA        Manufacturer schema:
#SCHEMA        Property	     Description	                    Example	                    Empty Value
#SCHEMA        uid	         64-bit unique identifier	        "a6e363e98ef77524"	        n/a
#SCHEMA        name	         The manufacturer's display name    "Texas Instruments Inc."	n/a
#SCHEMA        homepage_url	 The manufacturer's homepage url	"http://example.com"	    null    
    
    # Manufacturer Object - manufacturer
    my $Manufacturer = $Part->[$_]->{'manufacturer'};
    printResult("Mfg display name: ", $Manufacturer->{'name'}) if $verbose;
    
#SCHEMA        Description schema:
#SCHEMA        Property	    Description	                        Example	                            Empty Value
#SCHEMA        value	    The value of the description	    "The TLC274AID is a precision ..."	n/a
#SCHEMA        attribution	Information about the data source	<Attribution object>	            n/a    
    
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
    
    
#SCHEMA        SpecValue schema:
#SCHEMA        Property	       Description	                           Example	                Empty Value
#SCHEMA        value	       The value of the product property	   ["5.0"]	                []
#SCHEMA        min_value	   The minimum value (if ranged 
#SCHEMA                        quantitative value)	                   "2.2"	                null
#SCHEMA        max_value	   The maximum value (if ranged 
#SCHEMA                        quantitative value)	                   "10.8"	                null
#SCHEMA        display_value   Value and unit as a string, 
#SCHEMA                        formatted for humans	                   "170 mV"	                ""
#SCHEMA        metadata	       Spec metadata information	           <SpecMetadata object>	n/a
#SCHEMA        attribution	   Information about the data source	   <Attribution object>	    n/a    
    
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
    
#SCHEMA        Category schema:
#SCHEMA        Property	        Description	                                   Example	                Empty Value
#SCHEMA        uid	            64-bit unique identifier	                   "b62d7b27870d6dea"	    n/a
#SCHEMA        name	            The category node's name	                   "Capacitors"	            n/a
#SCHEMA        parent_uid	    64-bit unique identifier of parent 
#SCHEMA                         category node	                               "ab34663e9a1770f3"	    null
#SCHEMA        children_uids	JSON array of children uid's	               ["d9ed14e7e8cc022a", 
#SCHEMA                                                                        "41398c33764e9afe"]	    []
#SCHEMA        ancestor_uids	JSON array of ancestor uid's with parent
#SCHEMA                         ordered last	                                ["55da98d064fd8e1d", 
#SCHEMA                                                                         "ab34663e9a1770f3"]	    []
#SCHEMA        ancestor_names	JSON array of ancestor node names	            ["Electronic Parts", 
#SCHEMA                                                                         "Passive Components"]	[]
#SCHEMA        num_parts	    Number of parts categorized in category node	1000000	                null
#SCHEMA        imagesets	    Hidden by default (See Include Directives)	    [<ImageSet object>]	    []
    
    # Add additional category uids to @Category_UIDS array
    push @Category_UIDS, @{$Part->[$_]->{'category_uids'}};  
    
#SCHEMA        PartOffer schema:
#SCHEMA        Property	            Description	                                    Example	                               Empty Value
#SCHEMA        sku	                The seller's part number	                    "67K1122"	                           n/a
#SCHEMA        seller	            Object representing the seller	                <Seller object>	                       n/a
#SCHEMA        eligible_region	    The (ISO 3166-1 alpha-2) or (ISO 3166-2) 
#SCHEMA                             code indicating the geo-political  
#SCHEMA                             region(s) for which offer is valid	            "US-NY"	                               null
#SCHEMA        product_url	        URL for seller landing page	                    "http://octopart.com/redirect/XXXX"	   null
#SCHEMA        octopart_rfq_url	    URL for generating RFQ through Octopart	        "http://octopart.com/rfq/XXXX"	       null
#SCHEMA        prices	            Dictionary mapping currencies to lists 
#SCHEMA                             of (Break, Price) tuples	                    See notes: PartOffer.prices	           n/a
#SCHEMA        in_stock_quantity	Number of parts seller has available	        See notes: PartOffer.in_stock_quantity n/a
#SCHEMA        on_order_quantity	Number of parts on order from factory	        2000	                               null
#SCHEMA        on_order_eta	        ISO 8601 formatted ETA of order from factory    "2017-10-29T12:00:00Z"	               null
#SCHEMA        factory_lead_days	Number of days to acquire parts from factory	42	                                   null
#SCHEMA        factory_order_multiple	Order multiple for factory orders	        1000	                               null
#SCHEMA        order_multiple	    Number of items which must be ordered together	See notes: PartOffer.order_multiple	   null
#SCHEMA        moq	                Minimum order quantity	100	null
#SCHEMA        packaging	        Form of offer packaging (e.g. reel, tape)	    See notes: PartOffer.packaging	       null
#SCHEMA        is_authorized	    True if seller is authorized by manufacturer	See notes: PartOffer.is_authorized	   n/a
#SCHEMA        last_updated	        ISO 8601 formatted time when offer was last 
#SCHEMA                             updated by the seller	                        "2017-10-18T07:12:00Z"	               n/a

    my $Offers = $Part->[$_]->{'offers'};
    foreach my $o (@$Offers)
    {      
        my $seller = $o->{'seller'}; # get seller object
        
#SCHEMA        Seller schema:
#SCHEMA        Property	        Description	                    Example	                 Empty Value
#SCHEMA        uid	            64-bit unique identifier	    "4a258f2f6a2199e2"	     n/a
#SCHEMA        name	            The seller's display name	    "Newark"	             n/a
#SCHEMA        homepage_url	    The seller's homepage url	    "http://example.com"	 null
#SCHEMA        display_flag	    ISO 3166 alpha-2 country 
#SCHEMA                         code for display flag	        "US"	                 null
#SCHEMA        has_ecommerce	Whether seller has e-commerce	true	                 null
        
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
