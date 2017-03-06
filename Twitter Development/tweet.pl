#!/usr/bin/perl -w

# usage
# cat "Tweet Files/new-tweets-out-mix.txt" | ./tweet.pl
# cat "testtweets.txt" | ./tweet2.pl

# Tweets with an image need to enclose image in html comment.
# Redneck lawnmower for some serious cutting! <!--Drunk on Mower.jpg-->

use strict;
use warnings;
use Net::Twitter;
use Data::Dumper qw(Dumper);
use Try::Tiny;
# use POSIX;

$ENV{TWITTER_ACCESS_SECRET} = "i9qBHgcSewEtEz1CWa86vtF3kbK5szRhHR4lQAmRQ";
$ENV{TWITTER_CONSUMER_SECRET} = "nCe6C0Io0pHk6SI0uWg3Tsz5tj8fi2G62jvrzoUDos";
$ENV{TWITTER_ACCESS_TOKEN} = "65664359-C7asxBNAN6HVO6o8MNVo8ZLq0TZScNgG5I3YH39ua";
$ENV{TWITTER_CONSUMER_KEY} = "eKJZw78xnB5HnEUOkYvVnA";

# tweet("Will Rogers Says: \"Things in our country run in spite of government. Not by the aid of it.\" #quote");


print "\n*********************************** start tweet2.pl  program.***********************************\n";
$| = 1; # flush after every write
$\ = ""; # output record separator

srand 123.45;
my $minutes = 60;
my $tweetcnt = 0;
my $tweetchars = 0;

while (<>) # Grab stdin lines
{
    next if /^\/\// || /^\s+/; # skip if // comment or blank line
    
    # print $_;
    # Tweets with an image need to enclose image in html comment.
    # Redneck lawnmower for some serious cutting! <!--Drunk on Mower.jpg-->

    if (/(.*?)<!--(.*)-->/)
    {
        # If the tweet text is greater than 118 chars there isn't enough
        # room for the image
        if (length $1 <= 118)
        {
            tweetmedia($1, $2); # send tweet and image
        } else
        {
            tweet($1); # send the tweet text only
        }
    } else
    {
        tweet($_); # send the tweet
    }
    delay_between_tweets(); # wait for next tweet
}

print "\n*********************************** end tweet2.pl  program.***********************************\n";

sub delay_between_tweets
{
    my $delay = sleep $minutes * (20.0 + rand 10);
#    print "-- delay = ".$delay."\n";
#    printf "== delay = %5.2f \n", $delay;
#    print Dumper localtime time;
# http://stackoverflow.com/questions/2149532/how-can-i-format-a-timestamp-in-perl
    print POSIX::strftime("----- %m/%d/%Y %H:%M:%S", localtime);
    printf " next after %d min %d sec\n", int $delay/60, $delay % 60;
#    printf " next after %.2f sec\n", $delay;   
}

sub tweetmedia
{
    my ($text, $piclink) = @_;
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
        
        my $retval = $twitter->update_with_media($text, [ $piclink ]);
        $tweetcnt++;
        chomp $text;
        $tweetchars = length $text;
        print "$tweetcnt: $text - chars: $tweetchars - media: $piclink\n";
    #  print Dumper $retval;
    } 
    catch
    {
        print join(" -----> ", "***** Error tweeting: $text", 
                    $_->code, $_->message, $_->error);
        print "\n";
    }
    
} # sub tweetmedia

sub tweet
{
  my ($text) = @_;

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
        
        my $retval = $twitter->update($text);
        $tweetcnt++;
        chomp $text;
        $tweetchars = length $text;
        print "$tweetcnt: $text - chars: $tweetchars\n";
    #  print Dumper $retval;
    } 
    catch
    {
        print join(" -----> ", "***** Error tweeting: $text", 
                    $_->code, $_->message, $_->error);
        print "\n";
    }

} # sub tweet



