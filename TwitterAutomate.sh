# Twitter Tweet Automation
while [ 1 ] # Infinite Loop Here
do
echo "================== Create Tweet Set =================="
./tweet-build-dev.pl
echo "================== Run automated tweets =================="
cat "Tweet Files/new-tweets-out.txt" | ./tweet-dev.pl
echo "================== End automated tweets =================="
done
