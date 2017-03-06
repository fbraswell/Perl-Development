#!/usr/bin/perl -w
######---------#!/usr/bin/perl5.8.9 -w

# This program is designed to mix up tweet messages from a variety of
# tweet archive files

use Mac::Errors;
use Data::Dumper;
#####  use Mac::Files;
#####  use Mac::Resources;
use File::Find;

$rootFolder = "tweet files";
$outputFile = ">tweet files/new-tweets-out.txt";
# array of files to scan - they must be txt files
# number are the number of lines to be included in daily tweet file
%fileNamesToTweet =
(
    'ESVQuotesTtags.txt' => 5, # has hash tags
    'ESVQuotesTlink.txt' => 5, # has link to SOM page in place of hash tags
    'Will-RogersTtags.txt' => 5, # has hash tags
    'Will-RogersTlink.txt' => 5, # has link to SOM page in place of hash tags
    'SpurgeonTtags.txt' => 5, # has hash tags
    'SpurgeonTlink.txt' => 5, # has link to SOM page in place of hash tags
    'ESVNAVQuotesTtags.txt' => 5, # has hash tags
    'ESVNAVQuotesTlink.txt' => 5, # has link to SOM page in place of hash tags
    'political-tweets.txt' => 0,
    'basic-daily-tweets.txt' => 1000,    # include all lines!
    'published-tweets.txt' => 15,
    'published-tweets10.txt' => 10, # This one is created below
    'frances-tweets.txt' => 4,
    'digital-redneck.txt' => 5,
    'southern-sayings.txt' => 5,
    'spurgeon-quotes.txt' => 4,
    'Will-Rogers-FMB-quotes.txt' => 4,
    'Will-Rogers-Gragert-quotes.txt' => 0,
    'Will-Rogers-Reeder-quotes.txt' => 0,
    'sons-of-korah.txt' => 3,
    'misc-tweets.txt' => 5,
    'spurgeon-audio.txt' => 0,
    'Ronald-Reagan-quotes.txt' => 3,
    'Christmas-tweets.txt' => 10,
    
);

# Frank-Braswells-iMac-4:WR info frankbraswell$ perl "Will Rogers Process.pl"

#define NUMSPUR 6
#define NUMWR 6
#define NUMSOK 3
#define NUMPOSTS 20

print "\n*********************************** start tweet-build.pl  program.***********************************\n";
$| = 1; # flush after every write
$\ = ""; # output record separator

#________________fill arrays from files

#The input record separator should match the platform's C compiler mappings of
# "\r\n" (CRLF), "\n" (LF) and "\r" (CR), which are often 
# (but not always, e.g., EBCDIC-based platforms [Peter Prymmer]):
#
#    000D 000A DOS
#    000A UNIX
#    000D Mac
#For Unicode-capable platforms, the input record separator should also match:
#
#    2028
#    2029

#    D O S CR LF    0044 004F 0053 000D 000A
#    U n i x  LF    0055 006E 0069 0078 000A
#    M a c CR       004D 0061 0063 000D
#    l i n e  LS    006C 0069 006E 0065 2028
#    p a r a  PS    0070 0061 0072 0061 2029
#    l i n e        006C 0069 006E 0065

# input record separator
# $/ = "\r"; # input line ending Mac
# $/ = "\012\015";
my $dailyTweets; # This array will hold tweet set
my %tweetsHash; # contains tweet set arrays indexed by file name
print "__________ read tweets _________\n";
foreach(keys %fileNamesToTweet)
{
    $fn = "$rootFolder/$_";
    my @test;
    # read file into array called @test
    get_tweets(\@test, $fn);
    # get rid of comments and blank lines
    print "$fn ";
    print "^^ size of array with lines: ", scalar @test, "";
    
    # Get rid of blank lines & comment lines starting with "//"
    @test = grep /\w/ && !/^\/\//, @test;
    print " ^^ size of array: ", scalar @test, "\n";
    
    # otherwise add other tweet arrays to hash
    $tweetsHash{$_} = \@test;
#    print "== stash array in hash; hash size: ", scalar keys %tweetsHash,"\n";
} # foreach(keys %fileNamesToTweet)

my ($pubTweets, $pubTweets10);
# Remove 'published-tweets.txt', extract the last 10 line into another array
# then put both of them back into $tweetsHash
$pubTweets = delete $tweetsHash{'published-tweets.txt'};

# The most recent tweets are the last 10
@$pubTweets10 = splice( @$pubTweets, -10, 10 );

# Place both of the arrays back into the tweetsHash
$tweetsHash{'published-tweets.txt'} = $pubTweets;
$tweetsHash{'published-tweets10.txt'} = $pubTweets10;

# remove daily tweets array and delete it from the hash
$dailyTweets = delete $tweetsHash{'basic-daily-tweets.txt'};
delete $fileNamesToTweet{'basic-daily-tweets.txt'};
# print "== found basic-daily-tweets; length: ", scalar @$dailyTweets, "\n";

print "== stash array in hash after delete; hash size: ", scalar keys %tweetsHash,"\n";
print "== found basic-daily-tweets; length: ", scalar @$dailyTweets, "\n";
# print "-Daily Tweets:", Dumper($dailyTweets), "\n";
# Begin adding tweets to @dailyTweets
print "__________ inject tweets _________\n";
foreach(keys %fileNamesToTweet)
{
print "** inject array: ", $_, " ";
inject_tweets_group($dailyTweets, # inject tweets into dailyTweets array
                    $tweetsHash{$_}, # get array of tweets
                    $fileNamesToTweet{$_} # get number to inject
                    ); # add third param to print
}

print "\nnumber of lines to tweet: ", scalar @$dailyTweets, "\n";

# Output file
my $fOut = $outputFile;
open $FOUT, $fOut; # output Unicode UTF-8 encoding 
binmode $FOUT, ':utf8';

# print "-Daily Tweets:", Dumper($dailyTweets), "\n";

foreach(@$dailyTweets)
{
    # output a line & CR if entry is defined
    print $FOUT $_, "\n" if (defined);
}
# print $FOUT @$dailyTweets; # DEBUG

close $FOUT;

print "\n*********************************** end tweet-build.pl program.***********************************\n";

# die "*** stop program here! ***\n";

# Fold $numtoinject tweets from $inject array into Daily Tweets array, $dtweets
# Print results if $prnt variable present
# Extract $numtoinject tweets based on a calculation that will rotate through the
# tweets over time
# Inject the extracted tweets into Daily Tweets, $dtweets, evenly through the array, so 
# they aren't bunched in one place.
sub inject_tweets_group
{
	my ($dtweets, $inject, $numtoinject, $prnt) = @_;
	
	my $len = scalar @$inject;
	
	if (! $len ) # return if no tweets in array
	{
		print " - no tweets in array to inject\n";
		return;
	}
    if (! $numtoinject)
    {
        print " - 0 tweets to inject\n";
        return;
    }
	my $tweetgroups = scalar @$inject / $numtoinject;

	# find where today's group is using day of year to
	# cycle through the groups
	# $groupnum = $tweetgroups % $dayofyear;
	my $dayofyear = (localtime)[7];
	my @tweetgroup;
	my $groupnum = $dayofyear % ($tweetgroups + 1);
	print " - array len: $len; num groups: $tweetgroups; todays group num: $groupnum;";
	if ( $len - $numtoinject * $groupnum >= $numtoinject )
	{ # grab $numtoinject tweets from the group
		# from within array
		print " - inside array, not at end\n";
		@tweetgroup = splice @$inject, $groupnum * $numtoinject, $numtoinject;
	} else
	{ # grab last $numtoinject tweets if less than 6 elements from end of array
		print " - last $numtoinject tweets\n";
		@tweetgroup = splice @$inject, -$numtoinject, $numtoinject;
	}
	
	print "--extracted tweet group\n" if defined $prnt;
	map { print "$_\n";} @tweetgroup if defined $prnt;
	print "--\n" if defined $prnt;
	
	# insert  quotes 
	my $insert = scalar @$dtweets;
	my $gap = $insert / $numtoinject; # space between indexes

	# work from the end of the array down, otherwise
	# indexes will shift as array is lengthened with each insert
	while ( $insert > 0 )
	{ # grab tweets and put it into position
		splice @$dtweets, $insert, 0, shift @tweetgroup;
		$insert -= $gap;
	}
} # sub inject_tweets_group


#_______________________________________________________________
# pass the tweet array to be filled and the 
# file name to fetch the tweets from
sub get_tweets
{
my ($tweets, $fn) = @_;

	# if the filename is an alias then get the actual link and filename
	if ( $fn =~ /txt alias/ )
	{
	my $alias_path;
	$alias_path = $fn;
	my $link = eval 
	{
		my $res = FSpOpenResFile( $alias_path, 0 ) or warn( "WARN open: $Mac::Errors::MacError: $fn" );
		# get resource by index; get first "alis" resource
		my $alis = GetIndResource( 'alis', 1 ) or warn( "WARN resource: $Mac::Errors::MacError $fn" );
		ResolveAlias( $alis );
	};

	if( $@ ) { warn "WARN eval: $@\n"; return; }
	$fn = $link;
	
	print "fn: $fn\n--alias file: $link\n\n";
	}

# Input file Political Tweets
# my $op = open($FH, $fn);
my $FH;
if(open($FH, $fn))
{
#    print "** file opened $fn\n";
} else
{
#    print "** cannot open $fn\n";
    return;
}
my $file;
{ local $/=undef;  $file=<$FH>; }
utf8::upgrade($file); # convert to Unicode UTF-8 encoding
# ($\) = (/(\r\n|\r|\n)/);  # make output rec-separator same as input
@$tweets=split /[\r\n]+/, $file;

# @$tweets = <$FH>; 
close $FH;
# map chomp, @$tweets;
} # sub get_tweets
#____________________________________________
