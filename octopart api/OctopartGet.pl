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

my @mpn = ( "1n4148" );
# Open needed files

#	my $FHTfriends; # file handle
#	my $FH = $FHTfriends;
#	my $fnTfriends = 'twitter_friends_JSON.txt'; # file name for reading friends
#	my $fn = $fnTfriends;
#	if(open($FH, $fn))
#	{
#		print "** file opened $fn\n";
#	} else
#	{
#		$FH = 0;
#		print "** cannot open $fn, FH = $FH\n";
#		$FHTfriends = $FH;
#	#    return;
#	}
#	$FHTfriends = $FH;

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

my $part = $mpn[0];

$octopart->buildQuery({'pretty_print'=>'true'});
# $octopart->GET('/api/v3/parts/match?apikey=4ed77e1e&queries=[{"mpn":"2n7000"}]&pretty_print=true');
# $octopart->GET("/api/v3/parts/match?apikey=4ed77e1e&queries=[{\"mpn\":\"$part\"}]");
$octopart->GET('/api/v3/parts/match'
                . '?' . 'apikey=4ed77e1e'
                . '&' . "queries=[{\"mpn\":\"$part\"}]"
                . '&' . 'include[]=descriptions'
                . '&' . 'include[]=specs'
 #               . '&' . 'pretty_print=true'
                );
# $octopart->GET('/api/v3/parts/match', {'apikey' => '4ed77e1e'});
# $octopart->request('GET', 'http://octopart.com/api/v3/parts/match', 'request body content');
print "\nHTTP request responseCode: ", $octopart->responseCode(), "\n";
# print $octopart->responseCode();
#    print "\nStart responseContent\n";
#    print $octopart->responseContent();
#    print "\nEnd responseContent\n";

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

# Results items is an arry of parts information
my $Part = $PartsMatchResult->[0]->{"items"};
printResult("Number in items (parts) array: ", scalar @{$Part});

#    getItems(0);
#    getItems(1);
#    getItems(2);
for (my $i=0; $i < scalar @{$Part} ;$i++)
{
    getItems($i);
}

print "\n*********************************** end program $0  program.***********************************\n";

# Get item (parts) information
sub getItems
{
    $_ = shift; # grab array index
    printResult("items $_ class: ", $Part->[$_]->{'__class__'});
    printResult("items $_ mpn: ", $Part->[$_]->{'mpn'});
    printResult("items $_ short desc: ", $Part->[$_]->{'short_description'});
    printResult("items $_ octopart url: ", $Part->[$_]->{'octopart_url'});
    # Brand Object - brand
    my $Brand = $Part->[$_]->{'brand'};
    printResult("Brand Name: ", $Brand->{'name'});
    printResult("Brand url: ", $Brand->{'homepage_url'});
    # Manufacturer Object - manufacturer
    my $Manufacturer = $Part->[$_]->{'manufacturer'};
    printResult("Mfg display name: ", $Manufacturer->{'name'});
    # Description Object - descriptions
    my $Description = $Part->[$_]->{'descriptions'};
    printResult("number of descriptions: ", scalar @$Description);
    
    foreach my $d (@$Description)
    {
        printResult("    Description: ", $d->{'value'});
    }
    
    my $Partspecs = $Part->[$_]->{'specs'};
    while ( my ($key, $val) = each (%$Partspecs))
    {
        my $v = $val->{'display_value'};
        print "       spec key: ", $key, " -> value: ", $v?$v:'NULL', "\n";
    }
    
}

# Need to handle the case where result of query is a NULL object
sub printResult
{
    my ($str, $tmp) = @_;
    print $str, $tmp?$tmp:'NULL', "\n";
}
