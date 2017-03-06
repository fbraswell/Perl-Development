#!/usr/bin/perl -w
######---------#!/usr/bin/perl5.8.9 -w

use Mac::Errors;
#####  use Mac::Files;
#####  use Mac::Resources;
use File::Find;

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

get_tweets(\@politicaltweets, "tweet files/political-tweets.txt");
get_tweets(\@dailytweets, "tweet files/basic-daily-tweets.txt");
get_tweets(\@publishedtweets, "tweet files/published-tweets.txt");
get_tweets(\@francestweets, "tweet files/frances-tweets.txt");
get_tweets(\@dredtweets, "tweet files/digital-redneck.txt");
# get_tweets(\@salestweets, "tweet files/sales-pages.txt");
get_tweets(\@southerntweets, "tweet files/southern-sayings.txt");
get_tweets(\@spurgeontweets, "tweet files/spurgeon-quotes.txt");
get_tweets(\@wrfmbtweets, "tweet files/Will-Rogers-FMB-quotes.txt");
get_tweets(\@wrgragerttweets, "tweet files/Will-Rogers-Gragert-quotes.txt");
get_tweets(\@wrreedertweets, "tweet files/Will-Rogers-Reeder-quotes.txt");
get_tweets(\@sonsofkorahtweets, "tweet files/sons-of-korah.txt");
get_tweets(\@misctweets, "tweet files/misc-tweets.txt");
get_tweets(\@spurgeonaudio, "tweet files/spurgeon-audio.txt");
get_tweets(\@reagantweets, "tweet files/Ronald-Reagan-quotes.txt");
get_tweets(\@christmastweets, "tweet files/Christmas-tweets.txt");

# Output file
$fOut = ">tweet files/new-tweets-out.txt";
open $FOUT, $fOut; # output Unicode UTF-8 encoding 
binmode $FOUT, ':utf8';
# Output file1
$fOut1 = ">tweet files/new-tweets-out-mix.txt";
open $FOUT1, $fOut1; # output Unicode UTF-8 encoding 
binmode $FOUT1, ':utf8';

#____________________________________________
# Prepare arrays for use

# only pass through lines with chars, 
# discard blank lines, and any line beginning with //


# This are the basic daily tweets repeated each day
@dailytweets = grep /\w/ && !/^\/\//, @dailytweets;
dump_array(\@dailytweets, "--daily tweets:"); # add third param to print

@francestweets = grep /\w/ && !/^\/\//, @francestweets;
dump_array(\@francestweets, "--Frances tweets:"); # add third param to print

@publishedtweets = grep /\w/ && !/^\/\//, @publishedtweets;
dump_array(\@publishedtweets, "--Published tweets:"); # add third param to print

# Remove the last 10 lines from @publishedtweets, 
# which are the 10 most recent blog posts
@recentposts = splice( @publishedtweets, -10, 10 );
dump_array(\@recentposts, "--Recent posts from publishedtweets: "); # add third param to print

dump_array(\@publishedtweets, "--Published tweets -10:"); # add third param to print

@dredtweets = grep /\w/ && !/^\/\//, @dredtweets;
dump_array(\@dredtweets, "--Digital Redneck tweets:"); # add third param to print

@politicaltweets = grep /\w/ && !/^\/\//, @politicaltweets;
dump_array(\@politicaltweets, "--Political tweets:"); # add third param to print

@salestweets = grep /\w/ && !/^\/\//, @salestweets;
dump_array(\@salestweets, "--Sales tweets:"); # add third param to print

@southerntweets = grep /\w/ && !/^\/\//, @southerntweets;
dump_array(\@southerntweets, "--Southern Sayings tweets:"); # add third param to print

@spurgeontweets = grep /\w/ && !/^\/\// && length $_ < 140, @spurgeontweets;
dump_array(\@spurgeontweets, "--Spurgeon tweets:"); # add third param to print

@wrfmbtweets = grep /\w/ && !/^\/\//, @wrfmbtweets;
dump_array(\@wrfmbtweets, "--Will Rogers FMB tweets:"); # add third param to print

@wrgragerttweets = grep /\w/ && !/^\/\//, @wrgragerttweets;
dump_array(\@wrgragerttweets, "--Will Rogers Gragert tweets:"); # add third param to print

@wrreedertweets = grep /\w/ && !/^\/\//, @wrreedertweets;
dump_array(\@wrreedertweets, "--Will Rogers Reeder tweets:"); # add third param to print

@sonsofkorahtweets = grep /\w/ && !/^\/\//, @sonsofkorahtweets;
dump_array(\@sonsofkorahtweets, "--Sons of Korah tweets:"); # add third param to print

@misctweets = grep /\w/ && !/^\/\//, @misctweets;
dump_array(\ @misctweets, "--Misc tweets:"); # add third param to print

@spurgeonaudio = grep /\w/ && !/^\/\// && length $_ < 140, @spurgeonaudio;
dump_array(\@spurgeonaudio, "--Spurgeon tweets:"); # add third param to print

@reagantweets = grep /\w/ && !/^\/\// && length $_ < 140, @reagantweets;
dump_array(\@reagantweets, "--Reagan tweets:"); # add third param to print

@christmastweets = grep /\w/ && !/^\/\// && length $_ < 140, @christmastweets;
dump_array(\@christmastweets, "--Christmas tweets:"); # add third param to print


$dayofyear = (localtime)[7];
print "day of year: $dayofyear\n";

# ------Build array of tweets

# exchange 1 Frances tweet in location 2
# select different Frances quote each day
$indnum = $dayofyear % (scalar @francestweets);
# insert it into array, replacing loc 2 Frances tweet
splice @dailytweets, 1, 1, ($francestweets[$indnum]);


#	# insert 10 political tweets
#	$insert = scalar @dailytweets;
#	$gap = $insert / 10; # space between indexes
#
#	# work from the end of the array down, otherwise
#	# indexes will shift as array is lengthened with each insert
#	while ( $insert > 0 )
#	{ # grab top political tweet and put it into position
#		splice @dailytweets, $insert, 0, shift @politicaltweets;
#		$insert -= $gap;
#	}


# insert 10 most recent blog posts from the end of @tweetspublished 
# the most recent tweets are added to the end of this file each day

$insert = scalar @dailytweets;
$gap = $insert / 10; # space between indexes

# work from the end of the array down, otherwise
# indexes will shift as array is lengthened with each insert
while ( $insert > 0 )
{ # grab top recent post tweets and put it into position
		# adjust offset by $gap/2 to stagger quotes
	splice @dailytweets, $insert-$gap/2, 0, shift @recentposts;
	$insert -= $gap;
}


# insert 10 most recent blog posts from the end of @tweetspublished 
# the most recent tweets are added to the end of this file each day
print "--inject Spurgeon Audio; ";
$insert = scalar @dailytweets;
$gap = $insert / 4; # space between indexes - insert 4 most prev posts

# work from the end of the array down, otherwise
# indexes will shift as array is lengthened with each insert
while ( $insert > 0 )
{ # grab top recent post tweets and put it into position
    # adjust offset by $gap/2 to stagger quotes
	splice @dailytweets, $insert-$gap/2, 0, pop @spurgeonaudio;
	$insert -= $gap;
}

# in the following cases get blocks of tweets and inject them
print "--inject Will Rogers; ";
inject_tweets_group( \@dailytweets, \@wrfmbtweets, 14); # add third param to print

print "--inject Spurgeon; ";
inject_tweets_group( \@dailytweets, \@spurgeontweets, 14);  # add third param to print

print "--inject Sons of Korah; "; 
inject_tweets_group( \@dailytweets, \@sonsofkorahtweets, 3); # add third param to print

print "--inject Digital Redneck; ";
inject_tweets_group( \@dailytweets, \@dredtweets, 8); # add third param to print

print "--inject Southern; ";
inject_tweets_group( \@dailytweets, \@southerntweets, 7); # add third param to print

print "--inject Published tweets; ";
inject_tweets_group( \@dailytweets, \@publishedtweets, 22); # add third param to print

print "--inject Misc tweets; ";
inject_tweets_group( \@dailytweets, \@misctweets, 10); # add third param to print

print "--inject Reagan tweets; ";
inject_tweets_group( \@dailytweets, \@reagantweets, 3); # add third param to print

print "--inject Christmas tweets; ";
inject_tweets_group( \@dailytweets, \@christmastweets, 10); # add third param to print

# Send Tweets to output file
# Also send to stdout
$countlines = 0;
$countlinks = 0;
$countwrusa = 0;
foreach (@dailytweets)
{	# print $_, "\n";
	if (defined)
	{
		$countlines++;
		$countlinks++ if /http:/i;
        $countwrusa++ if /^\@WillRogersUSA/i;
	}
	print $FOUT $_, "\n" if defined $_;
}
close $FOUT;


# mix links and non-links lines evenly
@tweetslinks = ();
@tweetsnolinks = ();
foreach (@dailytweets)
{
    if (defined)
    {
        if (/http:/i)
        {
            # push onto array of link tweets
            push @tweetslinks, $_;
        }else
        {
            # push onto array of tweets without links
            push @tweetsnolinks, $_;
        }
    }# if (defined)
}# foreach (@dailytweets)

# merge the link and non-link tweets
# This assumes that neither one is more than twice the other
while ( scalar @tweetslinks + scalar @tweetsnolinks ) # run until both are empty
{
    if ( scalar @tweetslinks > scalar @tweetsnolinks )
    {# This is >
        print $FOUT1 shift @tweetsnolinks, "\n" if scalar @tweetsnolinks;
        print $FOUT1 shift @tweetslinks, "\n" if scalar @tweetslinks;
        print $FOUT1 shift @tweetslinks, "\n" if scalar @tweetslinks;
    }else
    {# This is <=
        # in the case of < add one extra line
        if ( scalar @tweetslinks < scalar @tweetsnolinks )
        {
            print $FOUT1 shift @tweetsnolinks, "\n" if scalar @tweetsnolinks;
        }

        print $FOUT1 shift @tweetsnolinks, "\n" if scalar @tweetsnolinks;
        print $FOUT1 shift @tweetslinks, "\n" if scalar @tweetslinks;
    }
    
    
}
close $FOUT1;


print "\nnumber of links tweets: $countlinks";
print "\nnumber of WRUSA tweets: $countwrusa";
print "\nnumber of lines: ", scalar @dailytweets;
print "\n*********************************** end tweet-build.pl  program.***********************************\n";

sub inject_tweets_group
{
	my ($dtweets, $inject, $numtoinject, $prnt) = @_;
	
	my $len = scalar @$inject;
	
	if (! $len ) # return if no tweets in array
	{
		print "none\n";
		return;
	}
	my $tweetgroups = scalar @$inject / $numtoinject;

	# find where today's group is using day of year to
	# cycle through the groups
	# $groupnum = $tweetgroups % $dayofyear;
	my $dayofyear = (localtime)[7];
	my @tweetgroup;
	my $groupnum = $dayofyear % ($tweetgroups + 1);
	print "--array len: $len; num groups: $tweetgroups; todays group num: $groupnum;";
	if ( $len - $numtoinject * $groupnum >= $numtoinject )
	{ # grab $numtoinject tweets from the group
		# from within array
		print "-inside array, not at end\n";
		@tweetgroup = splice @$inject, $groupnum * $numtoinject, $numtoinject;
	} else
	{ # grab last $numtoinject tweets if less than 6 elements from end of array
		print "-last $numtoinject tweets\n";
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
open $FH, $fn;
my $file;
{ local $/=undef;  $file=<$FH>; }
utf8::upgrade($file); # convert to Unicode UTF-8 encoding
# ($\) = (/(\r\n|\r|\n)/);  # make output rec-separator same as input
@$tweets=split /[\r\n]+/, $file;


# @$tweets = <$FH>; 
close $FH;
# map chomp, @$tweets;
}

#_______________________________________________________________
# dump array info to stdout
# pass array, name, param (can be anything, if undef don't print)
sub dump_array
{
	my ($a, $name, $prnt) = @_;
	my $n = scalar @$a; # get length
	print "$name $n\n";
	map {print "$_\n"} @$a if defined $prnt;
	print "-- end $name -----\n" if defined $prnt;
	}