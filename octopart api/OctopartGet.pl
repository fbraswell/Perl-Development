#!/usr/bin/env perl -w
use strict;
use warnings;

# Confused between versions of Perl
# Installed JSON module for Perl but cannot load it, Can't locate JSON.pm in @INC
# https://stackoverflow.com/questions/41143638/installed-json-module-for-perl-but-cannot-load-it-cant-locate-json-pm-in-inc

use LWP::Simple;
use Data::Dumper;

# use Scalar::Util 'blessed';
# use JSON qw( decode_json );
# http://www.tutorialspoint.com/json/json_perl_example.htm

use REST::Client;
use JSON;

print "\n*********************************** start program $0  program.***********************************\n";

my @mpn = ( "2n7000" );
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
$octopart->GET("/api/v3/parts/match?apikey=4ed77e1e&queries=[{\"mpn\":\"$part\"}]");
# $octopart->GET('/api/v3/parts/match', {'apikey' => '4ed77e1e'});
# $octopart->request('GET', 'http://octopart.com/api/v3/parts/match', 'request body content');
print "\nStart responseCode: ", $octopart->responseCode(), "\n";
# print $octopart->responseCode();
#    print "\nStart responseContent\n";
#    print $octopart->responseContent();
#    print "\nEnd responseContent\n";

my $json = JSON->new->allow_nonref;
my $jsonDecode = $json->decode($octopart->responseContent());

print "millisec: ", $jsonDecode->{"msec"}, "\n";
print "CLASS: ", $jsonDecode->{"__class__"}, "\n";
print "Request: ", $jsonDecode->{"request"}->{"__class__"}, "\n";
print "Request for mpn: ", $jsonDecode->{"request"}->{"queries"}[0]->{"mpn"}, "\n";
print "Results: ", $jsonDecode->{"results"}[0]->{"__class__"}, "\n";
# Test cases

#     screen name: FBRASWELL,  id string: 65664359
#     friends: 63343
#     statuses: 342954
#     followers: 57605

#    screen name: Ber97Luke, id string: 4854560182
#    friends: 819
#    followers: 838

# loadJSON('http://api.openweathermap.org/data/2.5/weather?q='+city+','+state+'&units=imperial&APPID=35ca93649d9a8dca0bf141ea63ff8947', gotWeather);
#function gotWeather(weather) 
#{
#  // Get the angle (convert to radians)
#  var angle = radians(Number(weather.wind.deg));
#  // Get the wind speed
#  var windmag = Number(weather.wind.speed);
#  var timeinfo = new Date();

#print "Local Weather\n";
#my $client = REST::Client->new();
#$client->GET('http://api.openweathermap.org/data/2.5/weather?q=Upland,IN&units=imperial&APPID=35ca93649d9a8dca0bf141ea63ff8947');
#print $client->responseContent();

#$client->GET('http://api.openweathermap.org/data/2.5/weather?zip=46989,us&units=imperial&APPID=35ca93649d9a8dca0bf141ea63ff8947');
#print $client->responseContent();

# --assetFeedID = 1279562671
# --assetAPIKey = "L1uSo1KL0bOjim4dn1PQz7GX044oRmHutAKmnyzjG7xAc6qy"
# --xivelyChannelName = "bootcount"
# local url = ("https://api.xively.com/v2/feeds/" .. assetFeedID .. ".json")
# https://api.xively.com/v2/feeds/1279562671.json
# 	headers =
#	{
#		["X-Api-Key"] = assetAPIKey,
#		Authorization = "Basic a25pZ2h0aGF3azprbmlnM3QzOHdr"
#	}
#print "\nXively\n";
## my $XivelyClient = REST::Client->new({params=>{datastreams => 'bootcount'}});
#my $XivelyClient = REST::Client->new();
#$XivelyClient->addHeader(
## 'X-ApiKey' => "L1uSo1KL0bOjim4dn1PQz7GX044oRmHutAKmnyzjG7xAc6qy",
# Authorization => "Basic a25pZ2h0aGF3azprbmlnM3QzOHdr",
#);
## JSON is default return structure
## $XivelyClient->GET('https://api.xively.com/v2/feeds/1279562671/datastreams/bootcount');
#$XivelyClient->GET('https://api.xively.com/v2/feeds/1279562671');
#
#print $XivelyClient->responseContent();

print "\n*********************************** end program $0  program.***********************************\n";
