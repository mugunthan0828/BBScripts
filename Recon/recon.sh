#!/bin/bash

# Function used for getting basic domains from certspotter
function certspotter(){
	printf "starting certspotter\n"
	curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $1 > domains.txt
	printf "Finished certspotter\n\n"
}

# Using the list from certspotter se what certsh can find in tearms of subdomains
function crtsh(){
	printf "Starting crtsh\n"
	cat domains.txt | while read line
	do
		echo $line
		curl -s https://crt.sh/?q=%.$line  | sed 's/<\/\?[^>]\+>//g' | grep $line >> subdomains
	done
	sort -u subdomains > subdomains.txt
	cat subdomains.txt | awk '!/Identity/' | awk '!/crt.sh/' > targets.txt
	rm subdomains
	printf "finished crtsh\n\n"
}

# Test default wordlist.whatever certspotter found
function wordlistUrl(){
        printf "Starting wordlistUrl\n"
        cat wordlistUrl | while read line
        do
                curl -s https://crt.sh/?q=%.$line.$1  | sed 's/<\/\?[^>]\+>//g' | grep $line.$1 >> subdomainsurl
        done
        sort subdomainsurl | uniq >> subdomains.txt
        cat subdomains.txt | awk '!/Identity/' | awk '!/crt.sh/' >> targetsandurls.txt
        rm subdomainsurl
        printf "finished wordlist\n\n"
}

# Clean up the list
function cleanup(){
       printf "Starting clean up\n"
cat targetsandurls.txt | awk '{$1=$1};1' >> targets.txt
        printf "finished clean up\n\n"
rm targetsandurls.txt
}

#Run httprobe on targets, httprobe written by TomNomNom
function probehttp(){
	printf "Starting httprobe\n"
	cat targets.txt | httprobe >> websitesAlive.txt
	printf "finished httprobe\n\n"
}

certspotter $1
crtsh
wordlistUrl $1
cleanup
probehttp

# List how many targets we found
#cat targets.txt | wc -l

# List how many live webpages we found
printf "Wesites found: "
cat websitesAlive.txt | wc -l
