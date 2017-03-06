#!/usr/bin/perl -w

# usage
# cat "Tweet Files/new-tweets-out.txt" | ./tweet-dev.pl
# cat "Tweet Files/new-tweets-out-mix.txt" | ./tweet-dev.pl
# cat "testtweets.txt" | ./tweet-dev.pl

# Tweets with an image need to enclose image in html comment.
# Redneck lawnmower for some serious cutting! <!--Drunk on Mower.jpg-->

use strict;
use warnings;
use Net::Twitter;
use Data::Dumper qw(Dumper);
use Try::Tiny;
# use POSIX;

# Psalm Daily Quotes KJV Twitter App
# https://apps.twitter.com/app/370158/keys
# 8-23-16 regenerated tokens because started getting the following error message!
# =====> Tweet Error! = Return Code: 401, Error Message: Authorization Required, Description: Invalid or expired token. at tweet-dev.pl line 132
#    Consumer Key (API Key)     eKJZw78xnB5HnEUOkYvVnA
#    Consumer Secret (API Secret)    nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos
#    Access Level     Read and write (modify app permissions)
#    Owner     FBRASWELL
#    Owner ID     65664359
# Access Token     65664359-8jwQ1bP6XNc7uahW9MCxghJg0K5L7hYsFlty4AqOV
# Access Token Secret     tmsMn3o36JKUT4ce4gMaLcXEFnMv93Nco1NSoURyv5eD0
$ENV{TWITTER_CONSUMER_KEY} = "eKJZw78xnB5HnEUOkYvVnA";
$ENV{TWITTER_CONSUMER_SECRET} = "nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos";
$ENV{TWITTER_ACCESS_TOKEN} = "65664359-8jwQ1bP6XNc7uahW9MCxghJg0K5L7hYsFlty4AqOV";
$ENV{TWITTER_ACCESS_SECRET} = "tmsMn3o36JKUT4ce4gMaLcXEFnMv93Nco1NSoURyv5eD0";


# Old tokens
#    $ENV{TWITTER_ACCESS_SECRET} = "i9qBHgcSewEtEz1CWa86vtF3kbK5szRhHR4lQAmRQ";
#    $ENV{TWITTER_CONSUMER_SECRET} = "nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos";
#    $ENV{TWITTER_ACCESS_TOKEN} = "65664359-C7asxBNAN6HVO6o8MNVo8ZLq0TZScNgG5I3YH39ua";
#    $ENV{TWITTER_CONSUMER_KEY} = "eKJZw78xnB5HnEUOkYvVnA";

# tweet("Will Rogers Says: \"Things in our country run in spite of government. Not by the aid of it.\" #quote");
my $minBetweenTweets = 15;
my $randomDelay = 5;

print "\n*********************************** start $0  program.***********************************\n";
$| = 1; # flush after every write
$\ = ""; # output record separator

srand 123.45;
my $minutes = 60;
my $tweetcnt = 0;
my $tweetchars = 0;

my @test;
my $fn;
#get_tweets(\@test, $fn);
    # get rid of comments and blank lines
#    print "$fn ";
    
    @test = <>; # Grab tweets from stdin
    
    print "^^ size of array with lines: ", scalar @test, "";
    
    # Get rid of blank lines & comment lines starting with "//"
    @test = grep /\w/ && !/^\/\//, @test;
    print " ^^ number of actual tweets: ", scalar @test, "\n";
    my $len = scalar @test;
    my $tweetFail = 0; # did tweet fail to post
# stdin lines contain tweets which are piped in from cat
foreach (@test) # Grab stdin lines
{
#    next if /^\/\// || /^\s+/; # skip if // comment or blank line
    
    # print $_;
    # Tweets with an image need to enclose image in html comment.
    # Redneck lawnmower for some serious cutting! <!--Drunk on Mower.jpg-->

    if (/(.*?)<!--(.*)-->/) # if match includes image
    {
        # If the tweet text is greater than 118 chars there isn't enough
        # room for the image
        if (length $1 <= 118)
        {
            $tweetFail = tweetmedia($1, $2); # send tweet and image
        } else
        {
            # tweet($1); # send the tweet text only
            $tweetFail = tweetmedia($1); # send the tweet text only
        }
    } else # if no image with tweet
    {
        # tweet($_); # send the tweet
        $tweetFail = tweetmedia($_); # send the tweet
    }
    last if($tweetcnt >= $len); # if tweetcnt eq total number of tweets
    # if tweet fails wait for next tweet 
#     next if($tweetFail); # go right to next tweet if this one doesn't post
     delay_between_tweets(); # wait for next tweet
} # foreach (@test) # Grab stdin lines

print "\n*********************************** end $0 program.***********************************\n";
#_______________________________________________________________
sub delay_between_tweets
{
    # Delay includes defined delay, $minBetweenTweets, and a random
    # portion, so tweets do not have a predictable delay
    # Figure out next delay, including a random part of delay
    # rand [expr] - returns a random fractional number between 0 and expr
    my $delayMin = $minBetweenTweets + rand $randomDelay;
#    printf " next tweet after %d min\n", $delayMin;
    my $delay = $minutes * $delayMin;
    my $t = time();
    my @lt = localtime($t);
    my @newTime = localtime($t + $delay); # time for next tweet 
    print POSIX::strftime("        ----- Time now: %m/%d/%Y %H:%M:%S", @lt);
    printf ", next tweet in %d min %d sec ", int $delay/60, $delay % 60;
    print POSIX::strftime(" at %m/%d/%Y %H:%M:%S\n", @newTime);
# DEBUG #
    $delay = sleep $minutes * $delayMin;
#    my $delay = sleep $minutes * (20.0 + rand 10);
#    print "-- delay = ".$delay."\n";
#    printf "== delay = %5.2f \n", $delay;
#    print Dumper localtime time;
# http://stackoverflow.com/questions/2149532/how-can-i-format-a-timestamp-in-perl
#    print POSIX::strftime("----- %m/%d/%Y %H:%M:%S", localtime);
#    printf " next after %d min %d sec\n", int $delay/60, $delay % 60;
#    printf " next after %.2f sec\n", $delay;   
} # sub delay_between_tweets
#_______________________________________________________________
sub tweetmedia
{
    my ($text, $piclink) = @_;
    my $tweetProblem = 0; # no tweet problem assumed
    my $twitter = Net::Twitter->new(
    traits              => [ qw/API::RESTv1_1/ ],
    access_token_secret => $ENV{TWITTER_ACCESS_SECRET},
    consumer_secret     => $ENV{TWITTER_CONSUMER_SECRET},
    access_token        => $ENV{TWITTER_ACCESS_TOKEN},
    consumer_key        => $ENV{TWITTER_CONSUMER_KEY},
    user_agent          => 'FMBExample',
    ssl => 1,
  );
    try
    {
        if(defined $piclink) # if there is an image
        {
#            print "piclink defined: $piclink\n";
# DEBUG #
            # make sure $piclink is a valid file
            if( -r $piclink) # see if $piclink can be read
            {
                # if file valid post to Twitter
                my $retval = $twitter->update_with_media($text, [ $piclink ]);
            } else
            {
                # if file not readable attach notice to name & fail tweet
#                print "-- file $piclink cannot be read\n";
                $piclink .= " - noread image ***";
                $tweetProblem =  1; # tweet failed
            }
        } else # no image, tweet text only
        {
#            print "piclink not defined\n";
# DEBUG #
            my $retval = $twitter->update($text);
        }
        # try won't get to here if tweet fails above -> catch below
# xxxxx #        my $retval = $twitter->update_with_media($text, [ $piclink ]);
        $tweetcnt++;
        chomp $text;
        $tweetchars = length $text;
        print "$tweetcnt of $len: $text - chars: $tweetchars";
        print " - media: $piclink" if defined $piclink;
        
#        print "\n";
    #  print Dumper $retval;
    } # try
    catch
    {
        $tweetcnt++;
        chomp $text;
        $tweetchars = length $text;
        print "$tweetcnt of $len: $text - chars: $tweetchars";
        print " - media: $piclink" if defined $piclink;
        print "\n        =====> Tweet Error! = Return Code: ", $_->code,
                    ", Error Message: ", $_->message,
                    ", Description: ", $_->error;

#        print join("\n-----> ", "***** Error Return Code: ", 
#                    $_->code, $_->message, $_->error);
#        print "\n";
        # example: -----> 403 -----> Forbidden -----> Status is over 140 characters. at tweet-dev.pl line 146
        $tweetProblem =  1; # tweet failed
    }; # catch
    print "\n";
    return $tweetProblem; # return tweet status
} # sub tweetmedia
