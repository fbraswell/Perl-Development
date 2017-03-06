#!/usr/bin/perl -w
use strict;
use warnings;

# This program experiments with the twitter api
# printing tweets, and calculating followers, following stats
# and api usage information

# must run in Perl Development folder
# ./TwitterDevFoFrCmp.pl

use LWP::Simple;
use Data::Dumper;
use REST::Client;
# http://search.cpan.org/dist/Net-Twitter/lib/Net/Twitter.pod
use Net::Twitter;
use Scalar::Util 'blessed';
# use JSON qw( decode_json );
# http://www.tutorialspoint.com/json/json_perl_example.htm
use JSON;

$ENV{TWITTER_CONSUMER_KEY} = "eKJZw78xnB5HnEUOkYvVnA";
$ENV{TWITTER_CONSUMER_SECRET} = "nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos";
$ENV{TWITTER_ACCESS_TOKEN} = "65664359-8jwQ1bP6XNc7uahW9MCxghJg0K5L7hYsFlty4AqOV";
$ENV{TWITTER_ACCESS_SECRET} = "tmsMn3o36JKUT4ce4gMaLcXEFnMv93Nco1NSoURyv5eD0";

# Old tokens
#    $ENV{TWITTER_ACCESS_SECRET} = "i9qBHgcSewEtEz1CWa86vtF3kbK5szRhHR4lQAmRQ";
#    $ENV{TWITTER_CONSUMER_SECRET} = "nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos";
#    $ENV{TWITTER_ACCESS_TOKEN} = "65664359-C7asxBNAN6HVO6o8MNVo8ZLq0TZScNgG5I3YH39ua";
#    $ENV{TWITTER_CONSUMER_KEY} = "eKJZw78xnB5HnEUOkYvVnA";

# https://dev.twitter.com/rest/public/rate-limits
# http://www.karambelkar.info/2015/01/how-to-use-twitters-search-rest-api-most-effectively./

print "\n*********************************** start program $0  program.***********************************\n";

# Open friends file
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

# open followers file
my $FHTfollowers; # file handle
$FH = $FHTfollowers;
my $fnTfollowers = 'twitter_followers_JSON.txt'; # file name for reading followers
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

# open profile file
my $FHTmyprofile; # file handle
$FH = $FHTmyprofile;
my $fnTmyprofile = 'twitter_myprofile_JSON.txt'; # file name profile
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

print "Twitter\n";

# twitter credentials
# my   $consumer_key = 'eKJZw78xnB5HnEUOkYvVnA';
# my   $consumer_secret = 'nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos';
# my   $token = '65664359-C7asxBNAN6HVO6o8MNVo8ZLq0TZScNgG5I3YH39ua';
# my   $token_secret = 'i9qBHgcSewEtEz1CWa86vtF3kbK5szRhHR4lQAmRQ';

 my   $consumer_key = $ENV{TWITTER_CONSUMER_KEY};
 my   $consumer_secret = $ENV{TWITTER_CONSUMER_SECRET};
 my   $token = $ENV{TWITTER_ACCESS_TOKEN};
 my   $token_secret = $ENV{TWITTER_ACCESS_SECRET};


# prepare for calls to twitter
my $nt = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    consumer_key        => $consumer_key,
    consumer_secret     => $consumer_secret,
    access_token        => $token,
    access_token_secret => $token_secret,
);

# list rate limits
ratelimits();

my $uid = '65664359';
my $scrname = 'FBRASWELL';

# show braswell information
my $result2 = $nt->show_user({user_id => $uid, screen_name => $scrname});
# DEBUG    print "-Dump FBRASWELL info: ", Dumper($result2), "\n";
    print "- Followers from Twitter count: ", $result2->{'followers_count'}, " for $scrname\n";
    print "- Friends from Twitter count: ", $result2->{'friends_count'}, " for $scrname\n";
    print "- Statuses from Twitter count: ", $result2->{'statuses_count'}, " for $scrname\n";
    
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
    print "- Followers count from file: ", $result2->{'followers_count'}, " for $scrname\n";
    print "- Friends count from file: ", $result2->{'friends_count'}, " for $scrname\n";
    print "- Statuses count from file: ", $result2->{'statuses_count'}, " for $scrname\n";

# DEBUG die "stop here!";

my $result; # result of operations
my @twit_followers; # array of twitter followers
my $av; # array pointer 

print "\n= Get all followers files: \n";
my $cv = -1; # cursor value first loop
# followers_ids - Returns a reference to an array of numeric IDs for every user following the specified user. The order of the IDs may change from call to call. To obtain the screen names, pass the arrayref to "lookup_users".
# get all followers
#        do
#        {
#            print "-== cursor value: ", $cv, ", ";
#    #        $result = $nt->followers_ids({user_id => '65664359', screen_name => 'FBRASWELL', cursor => $cv});
#            $result = $nt->followers_ids({user_id => $uid, screen_name => $scrname, cursor => $cv});
#            $av = $result->{'ids'};
#            print "- array length: ", scalar @$av, ", ";
#            $cv = $result->{'next_cursor_str'};
#            push @twit_followers, @$av; # add to followers array
#            print "- followers array length: ", scalar @twit_followers, "\n";
#    #        $cv = 0; # early end for DEBUG
#        } while($cv);

# $result = $nt->rate_limit_status();
# print "-rate limit result:\n",Dumper($result->{'resources'}{'application'}{'/application/rate_limit_status'}),"\n";

# get followers_out file
my $FHTfollowers_out; # file handle
$FH = $FHTfollowers_out;
my $fnTfollowers_out = 'twitter_followers_JSON_out.txt'; # file name for reading followers
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

#    my $JSONencode;
#    # encode the array @twit_followers by sending its reference
#    $JSONencode = encode_json( \@twit_followers );
#    print $FHTfollowers_out $JSONencode;
# get followers file
# $readdata;
$bytesread = read $FHTfollowers_out, $readdata, 1000000;
my @fstats = stat $FHTfollowers_out;
# print "= file stat for followers_out: \n", Dumper(@fstats), "\n";
my @newTime = localtime($fstats[9]);
print "= $fnTfollowers_out ";
print POSIX::strftime("last access %m/%d/%Y %H:%M:%S, ", @newTime);
close $FHTfollowers_out;

# need to decode $readdata to build the Perl data structure
my $followersfile_out = decode_json($readdata);
print " # followers: ", scalar @$followersfile_out, "\n";

my %hfollowersfile_out; # create hash for followersfile_out
# map all the keys into the hash from the array
# this will be used later for quick comparisons
map {$hfollowersfile_out{$_} = 'dummy'} @$followersfile_out;

# -- get followers file
# $readdata;
$bytesread = read $FHTfollowers, $readdata, 1000000;
@fstats = stat $FHTfollowers;
# print "= file stat for followers: \n", Dumper(@fstats), "\n";
@newTime = localtime($fstats[9]);
print "= $fnTfollowers ";
print POSIX::strftime("last access %m/%d/%Y %H:%M:%S, ", @newTime);
close $FHTfollowers;
# $readdata is a string from the read
# DEBUG print "- read data: bytes: $bytesread, data: \n", Dumper($readdata), "\n";

# need to decode $readdata to build the Perl data structure
my $followersfile = decode_json($readdata);
print " # followers: ", scalar @$followersfile, "\n";

my %hfollowersfile; # create hash for followers
# map all the keys into the hash from the array
# this will be used later for quick comparisons
map {$hfollowersfile{$_} = 'dummy'} @$followersfile;

# find followers who exist in one array but not the other

my @notinfollowersfile = map { if ( exists $hfollowersfile{$_}){}else{$_} } @$followersfile_out;
print "** notinfollowersfile: ", scalar @notinfollowersfile, "\n";

my @notinfollowersfile_out = map { if ( exists $hfollowersfile_out{$_}){}else{$_} } @$followersfile;
print "** notinfollowersfile_out: ", scalar @notinfollowersfile_out, "\n";

my $followersfile_out_short;
@$followersfile_out_short = splice @$followersfile_out, 0, 1000; # grab first 200 items
print " # followers_out_short: ", scalar @$followersfile_out_short, "\n";

my $followersfile_short;
@$followersfile_short = splice @$followersfile, 0, 1000; # grab first 200 items
print " # followers_short: ", scalar @$followersfile_short, "\n";

@notinfollowersfile = [];
@notinfollowersfile = map { if ( exists $hfollowersfile{$_}){}else{$_} } @$followersfile_out_short;
print "** notinfollowersfile short: ", scalar @notinfollowersfile, "\n";

@notinfollowersfile_out = [];
@notinfollowersfile_out = map { if ( exists $hfollowersfile_out{$_}){}else{$_} } @$followersfile_short;
print "** notinfollowersfile_out short: ", scalar @notinfollowersfile_out, "\n";

# get 100 followers information
my @followersfile100;
    # grab/remove the first 100 elements of @$followersfile
@followersfile100 = splice @$followersfile, 0, 15;
print "\n== lookup ", scalar @followersfile100, " users\n";
my @lookupUsers = $nt->lookup_users({ user_id => \@followersfile100 });
# print "= look up multiple users: \n", Dumper(@lookupUsers), "\n";
# dumpProfile(shift @lookupUsers);
# print "Number of users: ", scalar $lookupUsers[0], "\n";
dumpProfile(@lookupUsers);

# DEBUG die "stop here after followers!";

print "\n= Get all Friends: \n";
my @twit_friends; # array of twitter friends
$cv = -1; # cursor value first loop
@$av = []; # new array
# friends_ids - Returns a reference to an array of numeric IDs for every user followed by the specified user. The order of the IDs is reverse chronological.
# get all friends
#    do
#    {
#        print "-== cursor value: ", $cv, ", ";
#        $result = $nt->friends_ids({user_id => $uid, screen_name => $scrname, cursor => $cv});
#        $av = $result->{'ids'};
#        print "- ar len: ", scalar @$av, ", ";
#        $cv = $result->{'next_cursor_str'};
#        push @twit_friends, @$av; # add to followers array
#        print "- friends ar len: ", scalar @twit_friends, "\n";
##        $cv = 0; # early end for DEBUG
#    } while($cv);
    
    # output friends information
my $FHTfriends_out; # file handle
$FH = $FHTfriends_out;
my $fnTfriends_out = 'twitter_friends_JSON_out.txt'; # file name for reading friends
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

$bytesread = read $FHTfriends_out, $readdata, 1000000;
@fstats = stat $FHTfriends_out;
# print "= file stat for followers_out: \n", Dumper(@fstats), "\n";
@newTime = localtime($fstats[9]);
print "= $fnTfriends_out ";
print POSIX::strftime("last access %m/%d/%Y %H:%M:%S,", @newTime);
close $FHTfriends_out;

# need to decode $readdata to build the Perl data structure
my $friendsfile_out = decode_json($readdata);
print " #friends : ", scalar @$friendsfile_out, "\n";

my %hfriendsfile_out; # create hash for friends
# map all the keys into the hash from the array
# this will be used later for quick comparisons
map {$hfriendsfile_out{$_} = 'dummy'} @$friendsfile_out;

# my $JSONencode;
# encode the array @twit_friends by sending its reference
#    $JSONencode = encode_json( \@twit_friends );
#    print $FHTfriends_out $JSONencode;
#    close $FHTfriends_out;

# $readdata;
# $bytesread = read $FHTfriends, $readdata, 1000000;
# $readdata is a string from the read
# DEBUG print "- read data: bytes: $bytesread, data: \n", Dumper($readdata), "\n";

# need to decode $readdata to build the Perl data structure
# my $friendsfile = decode_json($readdata);
# print "- friends array from file length: ", scalar @$friendsfile, "\n";

$bytesread = read $FHTfriends, $readdata, 1000000;
@fstats = stat $FHTfriends;
# print "= file stat for followers_out: \n", Dumper(@fstats), "\n";
@newTime = localtime($fstats[9]);
print "= $fnTfriends ";
print POSIX::strftime("last access %m/%d/%Y %H:%M:%S, ", @newTime);
close $FHTfriends;

# need to decode $readdata to build the Perl data structure
my $friendsfile = decode_json($readdata);
print " #friends: ", scalar @$friendsfile, "\n";

my %hfriendsfile; # create hash for friends
# map all the keys into the hash from the array
# this will be used later for quick comparisons
map {$hfriendsfile{$_} = 'dummy'} @$friendsfile;

# find friends who exist in one array but not the other

my @notinfriendsfile = map { if ( exists $hfriendsfile{$_}){}else{$_} } @$friendsfile_out;
print "** notinfriendsfile: ", scalar @notinfriendsfile, "\n";

my @notinfriendsfile_out = map { if ( exists $hfriendsfile_out{$_}){}else{$_} } @$friendsfile;
print "** notinfriendsfile_out: ", scalar @notinfriendsfile_out, "\n";

my $friendsfile_out_short;
@$friendsfile_out_short = splice @$friendsfile_out, 0, 1000; # grab first 200 items
print " # friends_out_short: ", scalar @$friendsfile_out_short, "\n";

my $friendsfile_short;
@$friendsfile_short = splice @$friendsfile, 0, 1000; # grab first 200 items
print " # friends_short: ", scalar @$friendsfile_short, "\n";

@notinfriendsfile = [];
@notinfriendsfile = map { if ( exists $hfriendsfile{$_}){}else{$_} } @$friendsfile_out_short;
print "** notinfriendsfile short: ", scalar @notinfriendsfile, "\n";

@notinfriendsfile_out = [];
@notinfriendsfile_out = map { if ( exists $hfriendsfile_out{$_}){}else{$_} } @$friendsfile_short;
print "** notinfriendsfile_out short: ", scalar @notinfriendsfile_out, "\n";

# find mutuals between friends and followers
# if doesn't exist
print "\n=== mutuals don't exist\n";
my @mutuals;
my @mutuals_out;
@mutuals = map { if ( exists $hfollowersfile{$_}){}else{$_} } @$friendsfile;
print "** mutuals followers friends: ", scalar @mutuals, "\n";

@mutuals_out = map { if ( exists $hfollowersfile_out{$_}){}else{$_} } @$friendsfile_out;
print "** mutuals_out followers friends: ", scalar @mutuals_out, "\n";

@mutuals = map { if ( exists $hfriendsfile{$_}){}else{$_} } @$followersfile;
print "** mutuals friends followers: ", scalar @mutuals, "\n";

@mutuals_out = map { if ( exists $hfriendsfile_out{$_}){}else{$_} } @$followersfile_out;
print "** mutuals_out friends followers: ", scalar @mutuals_out, "\n";

# if exists
print "\n=== mutuals exist\n";
@mutuals = map { if ( exists $hfollowersfile{$_}){$_}else{} } @$friendsfile;
print "** mutuals followers friends : ", scalar @mutuals, "\n";

@mutuals_out = map { if ( exists $hfollowersfile_out{$_}){$_}else{} } @$friendsfile_out;
print "** mutuals_out followers friends: ", scalar @mutuals_out, "\n";

@mutuals = map { if ( exists $hfriendsfile{$_}){$_}else{} } @$followersfile;
print "** mutuals friends followers: ", scalar @mutuals, "\n";

@mutuals_out = map { if ( exists $hfriendsfile_out{$_}){$_}else{} } @$followersfile_out;
print "** mutuals_out friends followers: ", scalar @mutuals_out, "\n";

# Dump Tweets------
# last 20 entries from my timeline
my $timeline = $nt->user_timeline({screen_name => 'FBRASWELL'});
# print Dumper($timeline);
# DEBUG dumpTweets($timeline);

ratelimits(); # report rate limits
print "\n*********************************** end $0 program.***********************************\n";
#---------------------------------------------------------------
sub dumpTweets
{
    my $tweetList = shift;
    my $i; # counter
    print "\nList some tweets\n";
    foreach my $tweet (@$tweetList)
    {
        $i++;
        printTweets($tweet);
    }
    print "Number of tweets in list: $i\n";
}
#---------------------------------------------------------------
# print tweet information
sub printTweets
{
    my $tweet = shift;
    # get text - text
    print "tweet text: ", $tweet->{text}, "\n";
    # get image - source
#    print "source: ", $tweet->{source}, "\n";
    # get media url - entities => media => media_url_https
    my $mediaURL = $tweet->{entities}{media}[0]{media_url_https};
    print "media URL: ", defined $mediaURL?$mediaURL:'undefined', "\n";
    # get fav cnt - favorite_count
    print "fav count: ", $tweet->{favorite_count}, "; ";
    # get retweet cnt - retweet_count
    print "retweet count: ", $tweet->{retweet_count}, "; ";
    # get author - user => screen_name
    print "tweet author name: ", $tweet->{user}{screen_name}, "; ";
    # get user id - user => id
    print "tweet author id: ", $tweet->{user}{id}, "; ";
    # 'created_at' => 'Sun Sep 04 07:12:47 +0000 2016'
    print "tweet created: ", $tweet->{created_at}, "\n\n";
}
#---------------------------------------------------------------
sub dumpProfile
{
    my $profileList = shift;
    my $i=0; # counter
    print "Number of profiles in list: ", scalar @$profileList, "\n";
    print "\nList some profiles\n";
    foreach my $profile (@$profileList)
    {
        $i++;
        print "----Profile Number: ", $i, "\n";
        printProfile($profile);
    }
    print "Number of profiles in list: $i\n";
}
#---------------------------------------------------------------
# print profile information
sub printProfile
{
#    my $allpro = shift;
#    my $pro = shift @$allpro; # get first one
    my $pro = shift;
#    print "profile info: ", Dumper(shift @$allpro), "\n";
# DEBUG   print "profile info: ", Dumper($pro), "\n";
#    (print "Name: ", $pro->{name}, "\n") | warn "Trouble printing Name: $! ";
#    print "Name: ", Dumper($pro->{name}), "\n";
    print "Name: ", $pro->{name}, "\n";
    print "Screen Name: ", $pro->{screen_name}, " ";
    print "User ID: ", $pro->{id_str}, " ";
    print "Location: ", $pro->{location}, " ";
    print "User Created: ", $pro->{created_at}, "\n";
    
    
    print "Followers: ", $pro->{followers_count}, " ";
    print "Friends: ", $pro->{friends_count}, " ";
    print "Number of tweets: ", $pro->{statuses_count}, "\n";
    
    print "Description: ", $pro->{description}, "\n";
    
    print "Profile Image: ", $pro->{profile_image_url}, "\n";
    print "Profile Background: ", $pro->{profile_background_image_url}, "\n";
    
    print "Last tweet: ", $pro->{status}{text}, "\n";
    print "Last tweet created: ", $pro->{status}{created_at}, "\n";
    
    
    print "\n";
}
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
print "---+ Rate Limit Status Remaining: $rlStatus_remaining, ";
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
print "---+ follower limit remaining: $follower_remaining,";
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
print "---+ friends limit remaining: $friends_remaining, ";
my $friends_limit = $rls->{'limit'};
print "limit: $friends_limit, ";
my $friends_reset = $rls->{'reset'};
print "reset time: friends_reset, ";
@newTime = localtime($friends_reset);
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