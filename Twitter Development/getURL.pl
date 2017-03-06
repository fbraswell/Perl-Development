#!/usr/bin/perl -w

use LWP::Simple;
use Data::Dump;
# Grab URLs from a file

# usage - pipe text into getURL.pl
# cat new-tweets-out-mix.txt | ./getURL.pl 
# cat "Tweet Files/Christmas-tweets.txt" | ./getURL.pl 

while ( <> )
{
 #   $i++;
 #   print "line: ".$i." - ".$_;
    if (/.*(http:.*?)\s/) 
 #   if ($1)
    {
        print;
        print "  ".$1;
        if ($1 =~ /deck/i)
        {
            print " *** found deck.ly ";
        }
        
        if ( @h = head($1) )
        {
            print " -- Page exists -- \n";
            $i = 0;
            $hlen = scalar @h;
            for (@h)
            {
                print "  header length: $hlen\n" if $i == 0;
                print "  $i -> $_\n" if $h[$i];
                $i++;
            }
#            print join("\n", @h);
#            print "$_ $h{$_}\n" for (keys %h);
#            print "$_ \n" for (@h);
#            print CORE::dump(%h), "\n";
        } else
        {
            print " @@ No Page @@ \n";
        } 
#        print "\n".$h;
        print "\n";
    }
    
} # while()