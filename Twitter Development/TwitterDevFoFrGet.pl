#!/usr/bin/perl -w
use strict;
use warnings;

use LWP::Simple;
use Data::Dumper;
use REST::Client;
# http://search.cpan.org/dist/Net-Twitter/lib/Net/Twitter.pod
use Net::Twitter;
use Scalar::Util 'blessed';
# use JSON qw( decode_json );
# http://www.tutorialspoint.com/json/json_perl_example.htm
use JSON;

# https://dev.twitter.com/rest/public/rate-limits
# http://www.karambelkar.info/2015/01/how-to-use-twitters-search-rest-api-most-effectively./

# print "--- Start Program - Twitter Test ---\n";
print "\n*********************************** start program $0  program.***********************************\n";

my $FHTfriends; # file handle
my $FH = $FHTfriends;
my $fnTfriends = 'twitter_friends_JSON.txt'; # file name for reading friends
my $fn = $fnTfriends;
if(open($FH, $fn))
{
    print "** file opened $fn\n";
} else
{
    $FH = 0;
    print "** cannot open $fn, FH = $FH\n";
    $FHTfriends = $FH;
#    return;
}
$FHTfriends = $FH;

my $FHTfollowers; # file handle
$FH = $FHTfollowers;
my $fnTfollowers = 'twitter_followers_JSON.txt'; # file name for reading friends
$fn = $fnTfollowers;
if(open($FH, $fn))
{
    print "** file opened $fn\n";
} else
{
    $FH = 0;
    print "** cannot open $fn, FH = $FH\n";
    
#    return;
}
$FHTfollowers = $FH;

my $FHTmyprofile; # file handle
$FH = $FHTmyprofile;
my $fnTmyprofile = 'twitter_myprofile_JSON.txt'; # file name for reading friends
$fn = $fnTmyprofile;
if(open($FH, $fn))
{
    print "** file opened $fn\n";
} else
{
    $FH = 0;
    print "** cannot open $fn, FH = $FH\n";
    
#    return;
}
$FHTmyprofile = $FH;

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

print "\nTwitter\n";

#    consumertoken='eKJZw78xnB5HnEUOkYvVnA',
#    consumersecret='nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos',
#    accesstoken='65664359-C7asxBNAN6HVO6o8MNVo8ZLq0TZScNgG5I3YH39ua',
#    tokensecret='i9qBHgcSewEtEz1CWa86vtF3kbK5szRhHR4lQAmRQ'

 my   $consumer_key = 'eKJZw78xnB5HnEUOkYvVnA';
 my   $consumer_secret = 'nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos';
 my   $token = '65664359-C7asxBNAN6HVO6o8MNVo8ZLq0TZScNgG5I3YH39ua';
 my   $token_secret = 'i9qBHgcSewEtEz1CWa86vtF3kbK5szRhHR4lQAmRQ';

# my $TwitterClient = REST::Client->new();
my $nt = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    consumer_key        => $consumer_key,
    consumer_secret     => $consumer_secret,
    access_token        => $token,
    access_token_secret => $token_secret,
);

ratelimits();

my $uid = '65664359';
my $scrname = 'FBRASWELL';

# show braswell information
my $result2 = $nt->show_user({user_id => $uid, screen_name => $scrname});
# DEBUG    print "-Dump FBRASWELL info: ", Dumper($result2), "\n";
    print "- Followers from Twitter count: ", $result2->{'followers_count'}, "\n";
    print "- Friends from Twitter count: ", $result2->{'friends_count'}, "\n";
    print "- Statuses from Twitter count: ", $result2->{'statuses_count'}, "\n";
    
# output profile information
my $FHTmyprofile_out; # file handle
$FH = $FHTmyprofile_out;
my $fnTmyprofile_out = '>twitter_myprofile_JSON_out.txt'; # file name for reading friends
$fn = $fnTmyprofile_out;
if(open($FH, $fn))
{
    print "** file opened $fn\n";
} else
{
    $FH = 0;
    print "** cannot open $fn, FH = $FH\n";
#    return;
}
$FHTmyprofile_out = $FH;

my $JSONencode;
$JSONencode = encode_json( $result2 );
print $FHTmyprofile_out $JSONencode;
close $FHTmyprofile_out;

my $readdata;
my $bytesread = read $FHTmyprofile, $readdata, 1000000;
# $readdata is a string from the read
# DEBUG print "- read data: bytes: $bytesread, data: \n", Dumper($readdata), "\n";

# need to decode $readdata to build the Perl data structure
$result2 = decode_json($readdata);
    print "- Followers count from file: ", $result2->{'followers_count'}, "\n";
    print "- Friends count from file: ", $result2->{'friends_count'}, "\n";
    print "- Statuses count from file: ", $result2->{'statuses_count'}, "\n";

# DEBUG die "stop here!";
# my $friends = $nt->friends;
# my $friends = $nt->friends_ids;
# my $friends = $nt->lookup_users({ user_id => '65664359' });
# my $friends = $nt->lookup_users({ screen_name => 'FBRASWELL' });
#    my $friends;
#    $friends = $nt->lookup_users({ screen_name => 'Ber97Luke, FBRASWELL' });
#    # print Dumper($friends);
#    print "look up screen name information: \n";
#    print "\n screen name: ", $friends->[0]{'screen_name'}, ",";
#    print " id string: ", $friends->[0]{'id_str'}, "\n";
#    print " friends: ", $friends->[0]{'friends_count'}, "\n";
#    print " followers: ", $friends->[0]{'followers_count'}, "\n";
#    print " friends/followers: ", $friends->[0]{'friends_count'}/$friends->[0]{'followers_count'}, "\n";
#    print " statuses: ", $friends->[0]{'statuses_count'}, "\n";

# $results = $nt->mentions;
# $results = $nt->rate_limit_status;
# print Dumper($results);
# $result = $nt->fetch('friends');
# print $result;


my $result; # result of operations
my @twit_followers; # array of twitter followers
my $av; # array pointer 
# $result = $nt->followers_ids({user_id => '65664359', screen_name => 'FBRASWELL', cursor => -1});
# $result = $nt->followers_ids({user_id => '4854560182', screen_name => 'Ber97Luke', cursor => -1});
# print "Result of followers_ids: \n", Dumper($result), "\n";
# my $hval;
#    print "-- Results of followers_ids - first call:\n";
#    foreach my $hval (sort (keys %$result))
#    {
#        print "Key: ", $hval, ", ";
#        $av = $result->{$hval};
#    #    if(ref($result->{$hval}) eq 'ARRAY')
#        if(ref($av) eq 'ARRAY')
#        {
#         my $len = @$av;
#         print "array length: ", $len, "\n";
#    #     print "array length av: ", scalar @$av, "\n";
#    #     print "array length: ", ($result->{$hval}[0]), "\n";
#    #     print "array length: $result->{$hval}) \n";
#    #     print Dumper($result->{$hval});
#        } else
#        {
#         print "value: ", $result->{$hval}, "\n";
#        }
#    } # foreach my $hval (sort (keys %$result))

print "= Get all followers: \n";
my $cv = -1; # cursor value first loop
# followers_ids - Returns a reference to an array of numeric IDs for every user following the specified user. The order of the IDs may change from call to call. To obtain the screen names, pass the arrayref to "lookup_users".
# get all followers
    do
    {
        print "-== cursor value: ", $cv, ", ";
#        $result = $nt->followers_ids({user_id => '65664359', screen_name => 'FBRASWELL', cursor => $cv});
        $result = $nt->followers_ids({user_id => $uid, screen_name => $scrname, cursor => $cv});
        $av = $result->{'ids'};
        print "- array length: ", scalar @$av, ", ";
        $cv = $result->{'next_cursor_str'};
        push @twit_followers, @$av; # add to followers array
        print "- followers array length: ", scalar @twit_followers, "\n";
#        $cv = 0; # early end for DEBUG
    } while($cv);

# $result = $nt->rate_limit_status();
# print "-rate limit result:\n",Dumper($result->{'resources'}{'application'}{'/application/rate_limit_status'}),"\n";

# output followers information
my $FHTfollowers_out; # file handle
$FH = $FHTfollowers_out;
my $fnTfollowers_out = '>twitter_followers_JSON_out.txt'; # file name for reading followers
$fn = $fnTfollowers_out;
if(open($FH, $fn))
{
    print "** file opened $fn\n";
} else
{
    $FH = 0;
    print "** cannot open $fn, FH = $FH\n";
#    return;
}
$FHTfollowers_out = $FH;

my $JSONencode;
# encode the array @twit_followers by sending its reference
$JSONencode = encode_json( \@twit_followers );
print $FHTfollowers_out $JSONencode;
close $FHTfollowers_out;

my $readdata;
my $bytesread = read $FHTfollowers, $readdata, 1000000;
# $readdata is a string from the read
# DEBUG print "- read data: bytes: $bytesread, data: \n", Dumper($readdata), "\n";

# need to decode $readdata to build the Perl data structure
my $followersfile = decode_json($readdata);
print "- followers array from file length: ", scalar @$followersfile, "\n";

print "= Get all Friends: \n";
my @twit_friends; # array of twitter friends
$cv = -1; # cursor value first loop
@$av = []; # new array
# friends_ids - Returns a reference to an array of numeric IDs for every user followed by the specified user. The order of the IDs is reverse chronological.
# get all friends
    do
    {
        print "-== cursor value: ", $cv, ", ";
        $result = $nt->friends_ids({user_id => $uid, screen_name => $scrname, cursor => $cv});
        $av = $result->{'ids'};
        print "- ar len: ", scalar @$av, ", ";
        $cv = $result->{'next_cursor_str'};
        push @twit_friends, @$av; # add to followers array
        print "- friends ar len: ", scalar @twit_friends, "\n";
#        $cv = 0; # early end for DEBUG
    } while($cv);
    
    # output friends information
my $FHTfriends_out; # file handle
$FH = $FHTfriends_out;
my $fnTfriends_out = '>twitter_friends_JSON_out.txt'; # file name for reading friends
$fn = $fnTfriends_out;
if(open($FH, $fn))
{
    print "** file opened $fn\n";
} else
{
    $FH = 0;
    print "** cannot open $fn, FH = $FH\n";
#    return;
}
$FHTfriends_out = $FH;

my $JSONencode;
# encode the array @twit_friends by sending its reference
$JSONencode = encode_json( \@twit_friends );
print $FHTfriends_out $JSONencode;
close $FHTfriends_out;

my $readdata;
my $bytesread = read $FHTfriends, $readdata, 1000000;
# $readdata is a string from the read
# DEBUG print "- read data: bytes: $bytesread, data: \n", Dumper($readdata), "\n";

# need to decode $readdata to build the Perl data structure
my $friendsfile = decode_json($readdata);
print "- friends array from file length: ", scalar @$friendsfile, "\n";

# last 20 entries from my timeline
#my $timeline = $nt->user_timeline({screen_name => 'FBRASWELL'});
#print Dumper($timeline);
ratelimits();
print "\n*********************************** end $0 program.***********************************\n";
# print "\n--- End Program - Twitter Test ---\n";

#---------------------------------------------------------------
sub ratelimits
{
my $result1;
# $result = $nt->update('Test Tweet!');
# print $result;
# $result1 = $nt->rate_limit_status(); # general status rate call - gives everything
# print "-rate limit result:\n", Dumper($result1->{'resources'}{'application'}{'/application/rate_limit_status'}),"\n";

my $rls = $result1->{'resources'}{'application'}{'/application/rate_limit_status'};

$result1 = $nt->rate_limit_status({resources => 'application'}); # specific call for application rates
$rls = $result1->{'resources'}{'application'}{'/application/rate_limit_status'};
my $rlStatus_remaining = $rls->{'remaining'};
print "+ Rate Limit Status Remaining: $rlStatus_remaining, ";
my $rlStatus_limit = $rls->{'limit'};
print "Limit: $rlStatus_limit, ";
my $rlStatus_reset = $rls->{'reset'};
print "Reset Time: $rlStatus_reset, ";
my @newTime = localtime($rlStatus_reset);
print POSIX::strftime("or %m/%d/%Y %H:%M:%S\n", @newTime);

# print "\n";
# print "- followers ids limit: \n", Dumper($result1->{'resources'}{'followers'}{'/followers/ids'}),"\n";
$result1 = $nt->rate_limit_status({resources => 'followers'}); # specific call for follower status rates
my $follower_remaining = $result1->{'resources'}{'followers'}{'/followers/ids'}{'remaining'};
print "+ follower limit remaining: $follower_remaining,";
my $follower_limit = $result1->{'resources'}{'followers'}{'/followers/ids'}{'limit'};
print "limit: $follower_limit, ";
my $follower_reset = $result1->{'resources'}{'followers'}{'/followers/ids'}{'reset'};
print "reset time: $follower_reset, ";
@newTime = localtime($follower_reset);
print POSIX::strftime("or %m/%d/%Y %H:%M:%S\n", @newTime);

# print "\n";
# print "- friends ids limit: \n", Dumper($result1->{'resources'}{'friends'}{'/friends/ids'}),"\n";
$result1 = $nt->rate_limit_status({resources => 'friends'}); # specific call for friends status rates
$rls = $result1->{'resources'}{'friends'}{'/friends/ids'};
my $friends_remaining = $rls->{'remaining'};
print "+ friends limit remaining: $friends_remaining, ";
my $friends_limit = $rls->{'limit'};
print "limit: $friends_limit, ";
my $friends_reset = $rls->{'reset'};
print "reset time: friends_reset, ";
@newTime = localtime($follower_reset);
print POSIX::strftime("or %m/%d/%Y %H:%M:%S\n", @newTime);

# test specific rate calls
#    $result1 = $nt->rate_limit_status({resources => 'application'});
#    # $result1 = $nt->rate_limit_status({resources => 'application/application/rate_limit_status'});
#    print "-Dump appliction rates: ", Dumper($result1), "\n";
#
#    $result1 = $nt->rate_limit_status({resources => 'followers'});
#    # $result1 = $nt->rate_limit_status({resources => 'application/application/rate_limit_status'});
#    print "-Dump followers rates: ", Dumper($result1), "\n";
#
#    $result1 = $nt->rate_limit_status({resources => 'friends'});
#    # $result1 = $nt->rate_limit_status({resources => 'application/application/rate_limit_status'});
#    print "-Dump friends rates: ", Dumper($result1), "\n";
# dump everyting
# print "Dump rate limit result1: \n", Dumper($result1), "\n";
} # sub ratelimits