#!/usr/bin/env perl -w
use strict;
use warnings;

# This program imports tab delimited data  in file 'inputdata.txt' 
# which includes manufacturers part numbers. The first row must be label information.
# It looks up the part information on Octopart and populates the information for each part
# in a tab delimited output file.

# Confused between versions of Perl
# Installed JSON module for Perl but cannot load it, Can't locate JSON.pm in @INC
# https://stackoverflow.com/questions/41143638/installed-json-module-for-perl-but-cannot-load-it-cant-locate-json-pm-in-inc

# Perl is short for " Practical Extraction and Report Language," 
# although it has also been called a "Pathologically Eclectic Rubbish Lister,"

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
my $fname = 'inputdata.txt'; # Input file name
my $cname = 'categories.txt'; # file with category information
my $tod = gettimeofday; # Time of Day
my $prev_tod = gettimeofday(); # previous Time of Day
my $ratelimit = 0.5; # rate which calls can be made in seconds

my @headersRow; # Row of headers - first line of file  
my %headerNameIndex; # Need to know the index of each header name
my %partLoc = (); # Part location based on array above
my @partsOrder = (); # ordering of parts in the input spreadsheet file
# my $i = 0; # Count the input lines and parts

my @mpn; # List of manufacturer part numbers - drives program, line by line
my @GSheaders; # Header information, first row, for output file
my %GSvalues = (); # init Hash for the values of each row of spreadsheet
my $partCount = 1; # init - Count each part looked up for output line
    # Narrow down the list of seller to these vendors
my @sellerList = ('Newark', 'Digi-Key', 'Mouser', 'Arrow', 'element14');
my $octopart; 
    # Init data structures 
my %AllCatagories = (); # Keep track of all catagories (key) & UIDS (val) found across parts
my %AllInputCategories = (); # all categories input from file
# my @AllCategory_UIDS = (); # Collect all category UIDS found across parts
my @Category_UIDS = (); # Collect all category UIDS
my %Category_UIDS_hash = (); # no dups in hash keys
my @Categories = (); # Collect all categories 
my %Categories_hash = (); # Text  # no dups in hash keys 
my @Descriptions = (); # Collect all descriptions
my %Descriptions_hash = (); # no dups in hash keys
my @Short_Descriptions = (); # Collect all short descriptions
my %Short_Descriptions_hash = (); # no dups in hash keys
my @Specifications = (); # Collect all specification information
my %Specifications_hash = (); # no dups in hash keys
my @Manufacturers = (); # Collect all manufacturers
my %Manufacturers_hash = ();  # no dups in hash keys
my @Manufacturers_pn = (); # Collect all mpns
my %Manufacturers_pn_hash = ();  # no dups in hash keys
my @Vendors = (); # Collect all vendors
my %Vendors_hash = (); # no dups in hash keys
my @Vendors_pn = (); # Collect all vendors part numbers
my %Vendors_pn_hash = (); # no dups in hash keys
my @Pricing = (); # array of [qty, price] information 
my $requestedPN;
my $part; # current part number

print "\n*********************************** start program $0 program.***********************************\n";
# Part numbers go here

my $pnum = shift;
print "command line input: $pnum\n" if $pnum;

# Get categories & UIDs from file - input line looks like VVVV
# sorted all categories: Buffers, Drivers and Transceivers, UID 263deb371f9afdfa

open my $chandle, '<', $cname or die $!;
my @clines = (<$chandle>); # grab entire file by lines into array
close($chandle);
print "Number of category file lines: ", scalar @clines, "\n";
# Parse the line, locate the name and uid and save them in %AllInputCategories
# Keys are uid and value is name, so it can be looked up by uid later in program
map {my($name, $uid) = /sorted all categories: (.*), UID (.*)/; $AllInputCategories{$uid} = $name} @clines;

map {print "category: $AllInputCategories{$_}, UID: $_\n"} sort keys %AllInputCategories;

# my $fname = 'inputdata.txt';
open my $fhandle, '<', $fname or die $!;
my @lines = (<$fhandle>); # grab entire file by lines into array
close($fhandle);
chomp(@lines); # get rid of last character, \n
# map {print "$_ "} @lines;
    # Number of part numbers (rows) input.
print "Length of lines: ", scalar @lines, "\n";
    # In the end the partCount should equal the number in @lines
# my $partCount = 1; # init - Count each part looked up for output line

# Headers Example
# *Item Searched	Item	Description	MPN	Manufacturer	Vendor PN	Vendor					Category	Type	Location	Location 2	Quantity	Item	
# my @headersRow = qw (*Item Searched	Item	Description	MPN	Manufacturer	Vendor PN	Vendor					Category	Type	Location	Location 2	Quantity	Search);

    # First row must be the column names! - Headers
# my @headersRow = split "\t", shift @lines;
@headersRow = split "\t", shift @lines;
print "Headers: ";
map {print "$_, "} @headersRow;
print "\n";

    # Need to know the index of each header name
# my %headerNameIndex;
    # Put header names in as keys & indexes as values using slice
@headerNameIndex{@headersRow} = (0..$#headersRow);

foreach my $key (keys %headerNameIndex)
{
    print "header name: $key, index: $headerNameIndex{$key}\n";
}
# die "\nstop here\n";

# my %partLoc = (); # Part location based on array above
# my @partsOrder = (); # ordering of parts in the input spreadsheet file
# Organize input information according to the header labels
my $i = 0; # Count input lines
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
        # Store the address of @rowOfFields in hash location $partx using square brackets [] operator
    $partLoc{$partx} = [@rowOfFields];
#    die "\nStop here!\n";
}

    # test group of part names
# my @mpn = qw( 1N5235BTR 1N5251B 1N5819 512-1N5231B 1N5231B);

@mpn = @partsOrder; # list of parts from input file becomes @mpn to look up with api
print "\n____Parts found: ", scalar @mpn ,"\n";
map { print "$_ "} @mpn;
print "\n____End Parts\n";

    # If a part is in the command line - NOUSE
# @mpn =  ($pnum) if $pnum;

# ordering for the GS header
#    my @GSheaders = qw(Value    Search	Item	Description	MPN	
#                        Manufacturer  Vendor_PN	Vendor	Category	
#                        Type	Location	Location 2	Quantity);
                    
# my @GSheaders = @headersRow;
@GSheaders = @headersRow;
    # init Hash for the values of each row of spreadsheet
# my %GSvalues = ();
print "GSheader: " if $verbose;
    # Comma separated
# map {print $_, ', '} @GSheaders; 
    # Tab separated
map {print $_, "\t"} @GSheaders; 
print "\n";

#        # Narrow down the list of seller to these vendors
#    my @sellerList = (
#        'Newark', 'Digi-Key', 'Mouser', 'Arrow', 'element14',
#    );
print "Seller list: " if $verbose;
map {print $_, ", "} @sellerList if $verbose;
print "\n";
#        # Init data structures 
#    my %AllCatagories = (); # Keep track of all catagories found across parts
#    my @Category_UIDS = ();
#    my %Category_UIDS_hash = (); # no dups in hash keys
#    my @Categories = (); # Text 
#    my %Categories_hash = (); # Text  # no dups in hash keys 
#    my @Descriptions = ();
#    my %Descriptions_hash = (); # no dups in hash keys
#    my @Short_Descriptions = ();
#    my %Short_Descriptions_hash = (); # no dups in hash keys
#    my @Specifications = ();
#    my %Specifications_hash = (); # no dups in hash keys
#    my $requestedPN;

    # Create Octopart object
#    my $octopart = REST::Client->new({
$octopart = REST::Client->new({
        host => 'http://octopart.com',
#        'pretty_print' => 'true',
    });

foreach (@mpn)
{
    @Category_UIDS = ();
    %Category_UIDS_hash = (); # no dups in hash keys
    @Categories = (); # Text 
    %Categories_hash = (); # Text  # no dups in hash keys 
    @Descriptions = ();
    %Descriptions_hash = (); # no dups in hash keys
    @Short_Descriptions = ();
    %Short_Descriptions_hash = (); # no dups in hash keys
    @Specifications = ();
    %Specifications_hash = (); # no dups in hash keys
    @Manufacturers = (); # Collect all manufacturers
    %Manufacturers_hash = ();  # no dups in hash keys
    @Manufacturers_pn = (); # Collect all mpns
    %Manufacturers_pn_hash = ();  # no dups in hash keys
    @Vendors = (); # Collect all vendors
    %Vendors_hash = (); # no dups in hash keys
    @Vendors_pn = (); # Collect all vendors part numbers
    %Vendors_pn_hash = (); # no dups in hash keys
    %GSvalues = (); # Init for next spreadsheet row
    @Pricing = (); # pricing array
    
    print "\nRequest information on: $_\n" if $verbose;
    getPart($_); # Get the part information
    buildRow(); # get all GSvalues and output row
}

map {print "sorted all categories: $_, UID $AllCatagories{$_}\n"} sort keys %AllCatagories; # Dump  all categories found for all parts

print "\n*********************************** end program $0  program.***********************************\n";

#___________________________________________________________________________
sub getPart
{
#    my $part = shift;   # Get part name
     $part = shift;   # Get part name
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
    # Make call to Octopart API
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

    # Can we find item, manufacturer (Brand) with most information?
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
    
    map {getCategory($json, $_)} @Category_UIDS; # Get all categories for this part

    # only call getCategory once
#    getCategory($json, $Category_UIDS[0]) if ($Category_UIDS[0]);
    $GSvalues{'Category'} =  $Categories[0] if $Categories[0];

    #____________________________    
        # Removing duplicate strings from an array
        # http://www.perlmonks.org/?node_id=604547
        # Hash slices explained
        # http://www.webquills.net/web-development/perl/perl-5-hash-slices-can-replace.html

    if (scalar @Categories) # print information if there are @Categories
    {
        # Create hash to get rid of dups
        @Categories_hash{@Categories} = (); # use hash keys to get rid of dups
#        @AllCategories{@Categories} = (); # Save up all categories for end
        print "\nNumber of Sorted hash Categories: ", scalar keys %Categories_hash, "\n" if $verbose;
        map {print "all sorted hash categories: $_\n"} sort keys %Categories_hash if $verbose;
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
    if (scalar @Manufacturers)
    {
        # User hash to get rid of dups
        @Manufacturers_hash{@Manufacturers} = ();
        print "\nNumber of Sorted hash Manufacturer: ", scalar keys %Manufacturers_hash, "\n" if $verbose;
        map {print "all sorted hash manufacturer: $_\n" if $_} sort keys %Manufacturers_hash if $verbose;
    }
    #____________________________
    if (scalar @Manufacturers_pn)
    {
        # User hash to get rid of dups
        @Manufacturers_pn_hash{@Manufacturers_pn} = ();
        print "\nNumber of Sorted hash Manufacturer pn: ", scalar keys %Manufacturers_pn_hash, "\n" if $verbose;
        map {print "all sorted hash manufacturer pn: $_\n" if $_} sort keys %Manufacturers_pn_hash if $verbose;
    }
    #____________________________
    if (scalar @Vendors)
    {
        # User hash to get rid of dups
        @Vendors_hash{@Vendors} = ();
        print "\nNumber of sorted hash vendors: ", scalar keys %Vendors_hash, "\n" if $verbose;
        map {print "all sorted hash vendors: $_\n" if $_} sort keys %Vendors_hash if $verbose;
    }
    #____________________________
    if (scalar @Vendors_pn)
    {
        # User hash to get rid of dups
        @Vendors_pn_hash{@Vendors_pn} = ();
        print "\nNumber of sorted hash vendors pn: ", scalar keys %Vendors_pn_hash, "\n" if $verbose;
        map {print "all sorted hash vendors pn: $_\n" if $_} sort keys %Vendors_pn_hash if $verbose;
    }
    #____________________________
    
    # Fill in items from $inpStr - location, location 2, qty
    # Location	Location_2	Quantity
    unless (exists $partLoc{$part})
    {
        print "WARNING: This part: $part, doesn't exist in the hash.\n";
        return;
    }
} # getPart
#___________________________________________________________________________
sub buildRow
{
    # Fill in items we found from the API
    # Column names below
    # Value, *Item Searched, Item, Description, MPN, Manufacturer, Vendor PN, Vendor, , , , , 
    # Category, Type, Location, Location 2, Quantity, Search, , 
    
    
    # Fill in items that are already known for the part, 
    # such as location and quantity, in their respective columns
    my @partRow = @{$partLoc{$part}};
    $GSvalues{'Search'} = $part;
    $GSvalues{'*Item Searched'} = $part;
    $GSvalues{'Item'} =  $partRow[$headerNameIndex{'Item'}];
    $GSvalues{'Location'} =  $partRow[$headerNameIndex{'Location'}];
    $GSvalues{'Location 2'} =  $partRow[$headerNameIndex{'Location 2'}];
    $GSvalues{'Quantity'} =  $partRow[$headerNameIndex{'Quantity'}];
    
#    %GSvalues = (
#        Search => $part,
#        '*Item Searched' => $part,
#        Item => $partRow[$headerNameIndex{'Item'}],
#        Location => $partRow[$headerNameIndex{'Location'}],
#        'Location 2' => $partRow[$headerNameIndex{'Location 2'}],
#        Quantity => $partRow[$headerNameIndex{'Quantity'}],
#    );

    # Add categories by concatenating all found categories for this part
    my $concat = '';
    map {$concat .= "$_, "}  @Categories if $Categories[0];
    chop $concat; # Get rid of final space at the end
    chop $concat; # Get rid of final , at the end
    $GSvalues{'Category'} = $concat;
    
    # Vendor & Vendor PN
    # @Vendors and @Vendors_pn match for each index
    # @Pricing # also matching, info in @Pricing array - array of [qty, price] information
    # At this time look for Mouser
    my $i=0;
    foreach (@Vendors)
    {
        if (/Mouser/) # Search for Mouser
        {
            $GSvalues{'Vendor'} = $Vendors[$i];
            $GSvalues{'Vendor PN'} = $Vendors_pn[$i];
        }
        $i++; # next index
    }
    
    # Manufacturer & Manufacturer PN
    # @Manufacturers and @Manufacturers_pn match for each index
    # Grab the first Manufacturer Found for now
    $GSvalues{'Manufacturer'} = $Manufacturers[0] if $Manufacturers[0];
    $GSvalues{'MPN'} = $Manufacturers_pn[0] if $Manufacturers_pn[0];
    
    print "Spreadsheet Columns\n" if $verbose;

        # Print the spreadsheet columns with hash keys from header labels
    print "$partCount *==>";
    $partCount++;
    
    # Print the spreadsheet columns for each of the column names
    # If nothing defined in the column print naO
        # Comma separated
 #   map {defined $GSvalues{$_}?print "$GSvalues{$_}, ": print "na, " } @GSheaders;
        # Tab separated
    map {defined $GSvalues{$_}?print "$GSvalues{$_}\t": print "naO\t" } @GSheaders;
    print "\n";
    
} # buildRow
#___________________________________________________________________________
# Ask Octopart for category information
# Pass UID and fetch Category
sub getCategory
{
    my ($json, $c) = @_;
#    sleep(0.5);
#    select(undef,undef,undef, 0.5); # sleep - can be for less than 1 sec
    my $catName; # category name
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

    # Fine out if category uid is already known in %AllInputCategories
    if  (exists $AllInputCategories{$c})
    {
        $catName = $AllInputCategories{$c};
    } else # If not fetch from api
    {
        $octopart->GET("/api/v3/categories/$c"
                        . '?' . 'apikey=4ed77e1e');

    # Eventually try multi get categories                    
    # GET /categories/get_multi - Fetch multiple categories simultaneously

        my $rc = $octopart->responseCode();
        unless ($rc == 200)
        {
            print "*======== HTTP request category responseCode: ", $octopart->responseCode(), " Category: ", $c;
            if($rc == 429) # Hit rate limit of 3 requests per second
            {
                print " Hit rate limit!";
    #            sleep(1);
            }
            print "\n";
        }
        my $Category = $json->decode($octopart->responseContent());
        $catName = $Category->{'name'};
            
        # Save category and UID, only if retrieved for first time.
#        $AllCatagories{$Category->{'name'}} = $c if $Category->{'name'};
        $AllCatagories{$catName} = $c if $catName;
            
    } # end else If not fetch from api
    
#        print "category UID: $c, name: ", $Category->{'name'}, "\n";
#        push @Categories, $Category->{'name'} if $Category->{'name'};
        push @Categories, $catName if $catName;
        
        # Save category and UID
#        $AllCatagories{$Category->{'name'}} = $c if $Category->{'name'};
#        $AllCatagories{$catName} = $c if $catName;
        
        # Sample category data structure
#       {"ancestor_names": ["Electronic Parts", "Passive Components", "Resistors"], "uid": "91ee5ce4a8204a29", "num_parts": 708565, "ancestor_uids": ["8a1e4714bb3951d9", "7542b8484461ae85", "5c6a91606d4187ad"], "children_uids": [], "__class__": "Category", "parent_uid": "5c6a91606d4187ad", "name": "Through-Hole Resistors"}      
} # sub getCategory
#___________________________________________________________________________
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
    push @Manufacturers_pn, $Part->[$_]->{'mpn'} if $Part->[$_]->{'mpn'};
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
    push @Manufacturers, $Manufacturer->{'name'} if $Manufacturer->{'name'};
#SCHEMA        Description schema:
#SCHEMA        Property	    Description	                        Example	                            Empty Value
#SCHEMA        value	    The value of the description	    "The TLC274AID is a precision ..."	n/a
#SCHEMA        attribution	Information about the data source	<Attribution object>	            n/a    
    
    # Description Object - descriptions
    my $Description = $Part->[$_]->{'descriptions'};
    map {
            push @Descriptions, $_->{'value'}; 
        } @$Description if $verbose;
    my $descriptionToUse = $Descriptions[0]; # Grab one of the descriptions
    my $shortDescriptionToUse = $Part->[$_]->{'short_description'};
    
    printResult("number of descriptions: ", scalar @$Description) if $verbose;
    map {printResult("    Description: ", $_->{'value'});
#         push @Descriptions, $_->{'value'}; 
        } @$Description if $verbose;

#   unless ($_) # use only the first mfg part values for now
    unless ($_) # use only the first mfg part values for now
    {
#        %GSvalues = ( Item =>  $Part->[$_]->{'mpn'},
#                        MPN => $Part->[$_]->{'mpn'},
#                        Manufacturer => $Manufacturer->{'name'},
#                        Description => $Part->[$_]->{'short_description'},
#                    );
                    
#        $GSvalues{'Item'} = $Part->[$_]->{'mpn'};
#        $GSvalues{'MPN'} = $Part->[$_]->{'mpn'};
#        $GSvalues{'Manufacturer'} = $Manufacturer->{'name'};
        
        # if description array, use one of them
        # if not use short description if there is one
        
#        $GSvalues{'Description'} = $Part->[$_]->{'short_description'};
    if($descriptionToUse)
    {
        $GSvalues{'Description'} = $descriptionToUse;
    } elsif($shortDescriptionToUse)
    {
        $GSvalues{'Description'} = $shortDescriptionToUse;
    } else
    {
        $GSvalues{'Description'} = 'Description na';
    }
#        $GSvalues{'Description'} = $Part->[$_]->{'short_description'};
        
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
        push @Vendors, $seller->{'name'} if $seller->{'name'}; # Save seller name
        push @Vendors_pn, $o->{'sku'} if $o->{'sku'}; # Save the seller part number
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
#        unless ($_) # use only the first mfg part values for now
#        if (/mouser/i) # use only the first mfg part values for now
#        {
#            $GSvalues{'Vendor'} = $seller->{'name'};
#            $GSvalues{'Vendor_PN'} =  $o->{'sku'};
#        } # unless ($_)
        
        my $prices = $o->{'prices'}->{'USD'};
        if($prices) # Are there prices in USD?
        {
            my $qty1 = $prices->[0]; # first element of the price array is the 
                                     # min quantity
            print "            quantity: ", $qty1->[0], ", price: ", $qty1->[1], "\n" if $verbose;
            push @Pricing, $prices; # put info in @Pricing array - array of [qty, price] information
        } 
    }   # foreach my $o (@$Offers)
} # sub getItems

# Need to handle the case where result of query is a NULL object
sub printResult
{
    my ($str, $tmp) = @_;
    print $str, $tmp?$tmp:'NULL', "\n";
} # sub printResult
