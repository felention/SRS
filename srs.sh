#!/bin/bash

### Print version and check for new version
if [[ "${1,,}" =~ ^(v|version)$ ]]; then
    cvr='1'
    echo "Version $cvr"
    nvr="$(curl -s 'https://raw.githubusercontent.com/felention/SRS/refs/heads/main/version')"
    if (( $(echo "$nvr > $cvr" | bc -l) )); then
        echo "Version $nvr is available."
    fi
    exit
fi

### Check if there is an input
if [[ -z "$1" ]]; then
    echo "No Target set"
    exit
fi

### Set tool and target location
out="$HOME/srs"
tout="$out/$1"

### If archive of target exists, ask to scan again
if [[ -f "$out/$1.tar.gz" ]]; then
    read -p "It seems the target has been scanned before. Run again? " exists
    if [[ "${exists,,}" == "y" ]]; then
        tn="$(find "$out" -name "$1.tar.gz*" | sort | tail -1 | sed 's/.*\///')"
        if [[ "$tn" == "$1.tar.gz" ]]; then
            nn=0
        else
            nn="$(echo $tn | sed 's/.*\.gz.//')"
        fi
        nn="$((nn+1))"
        mv "$tout.tar.gz" "$tout.tar.gz.$nn"
    else
        exit
    fi
fi

### Make and go to target directory
mkdir -p "$tout"
cd "$tout"

### Set Chromium path
cbp="$HOME/chrome-linux/chrome"

### Subfinder
echo "Starting Subfinder..."
subfinder -all -o "subfinder.txt" -ip -active -d "$1"
cat "subfinder.txt" | sed 's/,.*//g' > subdomains.txt
cat "subfinder.txt" | awk -F ',' '{print $2}' > ips.txt
subs="$(wc -l < subdomains.txt)"
rm subfinder.txt

### crtsh
echo "Starting crtsh..."
crtc=0
curl -s "https://crt.sh/?q=%25.$1&output=json" > crt.txt
while [[ -z "$(grep "$1" crt.txt)" && -n "$(grep "error\|\[]\|502 Bad Gateway\|404 Not Found" crt.txt)" ]]; do
    sleep 5
    curl -s "https://crt.sh/?q=%25.$1&output=json" > crt.txt
    crtc=$((crtc+1))
    if [[ $crtc -eq 5 ]]; then
        echo "Skipping crtsh due to too many errors"
        rm crt.txt
        crtf=1
        crts=0
        break
    fi
done
if [[ $crtf -ne 1 ]]; then
    jq -r '.[].common_name' crt.txt > crt2.txt
    jq -r '.[].name_value' crt.txt >> crt2.txt
    sed -i '/*/d' crt2.txt
    grep "$1" crt2.txt > crt.txt
    awk -i inplace '!a[$0]++' crt.txt
    crts="$(wc -l < crt.txt)"
    cat crt.txt >> subdomains.txt
    while read -r line; do
        dig +short "$line" A >> ips.txt
    done < crt.txt
    sed -i 's/.*\.$//g; /^$/d' ips.txt
    rm crt.txt crt2.txt
fi

### Remove duplicates
awk -i inplace '!a[$0]++' subdomains.txt
awk -i inplace '!a[$0]++' ips.txt

### GoWitness Subdomains
echo "Starting GoWitness Subdomains..."
mkdir "GoWitness-Subdomains" && cd "$_"
gowitness scan file -f "../subdomains.txt" --chrome-path "$cbp" --driver gorod --write-db --screenshot-fullpage -T 20 --log-scan-errors
gwss="$(find screenshots/ -maxdepth 1 -type f | wc -l)"
gowitness report generate --zip-name "report.zip"
unzip "report.zip" -d "Report"
rm -rf "report.zip" /tmp/leakless-amd64-* /tmp/gowitness-v3-gorod-* /tmp/.org.chromium.Chromium.*
cd ..

### ISP Prep
echo "Starting ISP Prep..."
mkdir "ip-Split"
split -l 99 "ips.txt" "ip-Split/"
for file in ip-Split/*; do
    sed -i 's/^/"/g; s/$/", /g' "$file"
    sed -z -i 's/\n//g' "$file"
    sed -i 's/^/[/; s/, $/]/' "$file"
done

### ISP Check
echo "Starting ISP Check..."
count=0
for file in ip-Split/*; do
    curl -s http://ip-api.com/batch?fields=query,isp --data "$(cat $file)" >> isp.txt
    echo >> isp.txt
    count=$((count+1))
    if [[ "$count" -eq "44" ]]; then
        sleep 60
        count=0
    fi
done
rm -r "ip-Split/"

### ISP Parse
echo "Starting ISP Parse..."
sed -i 's/{"isp":"/\n/g; s/"}/\n/g' isp.txt
sed -i '/:/!d; s/".*"/ - /g' isp.txt
sed '/Defense.net/Id; /Akamai/Id; /Cloudflare/Id; /Fastly/Id; /CheetahMail/Id; /GoDaddy/Id; /Incapsula/Id; /Wix/Id; /SquareSpace/Id; /Namecheap/Id; /Web-hosting/Id' isp.txt > scan.txt
sed -i 's/.* //g' scan.txt

if [[ -s scan.txt ]]; then
    ### Masscan
    echo "Starting Masscan..."
    rate="$(cat scan.txt | wc -l)"
    rate=$((rate*1000))
    if [[ "$rate" -gt "25000000" ]]; then
        rate=25000000
    fi
    sudo masscan -iL scan.txt -p 0-65535 -oX ports.txt --rate "$rate"
    ipsi="$(wc -l < scan.txt)"
    masi="$(wc -l < ports.txt)"

    ### Port Parse
    echo "Starting Port Parse..."
    sed -i '/state="open"/!d' ports.txt
    sed -i 's/.*addr="//g; s/" addr.*portid="/:/g; s/".*//g' ports.txt
    awk -i inplace '!a[$0]++' ports.txt
else
    echo "Skipping Masscan and Port Parse as IPs aren't useful."
    ipsi=0
    masi=0
fi
rm scan.txt

if [[ -s ports.txt ]]; then
    ### GoWitness Ports
    echo "Starting GoWitness Ports..."
    mkdir "GoWitness-Ports" && cd "$_"
    gowitness scan file -f "../ports.txt" --chrome-path "$cbp" --driver gorod --write-db --screenshot-fullpage -T 20 --log-scan-errors
    gwps="$(find screenshots/ -maxdepth 1 -type f | wc -l)"
    gowitness report generate --zip-name "report.zip"
    unzip "report.zip" -d "Report"
    rm -rf "report.zip" /tmp/leakless-amd64-* /tmp/gowitness-v3-gorod-* /tmp/.org.chromium.Chromium.*
    cd ..
else
    echo "Skipping GoWitness Ports as there are no open ports or useful IPs."
    gwps=0
    if [[ -e ports.txt ]]; then
        rm ports.txt
    fi
fi

### Archiving
echo "Starting Archiving..."
cd ..
tar -zcvf "$1.tar.gz" "$1/"
rm -rf "$1/"

### Stats
echo
echo "Subfinder found:"
echo "$subs subdomain(s)"
echo
echo "crtsh found:"
echo "$crts subdomain(s)"
echo
echo "Masscan found:"
echo "$masi open port(s) from $ipsi IP address(es)"
echo
echo "GW-Sub screenshotted:"
echo "$gwss screenshot(s)"
echo
echo "GW-Ports screenshotted:"
echo "$gwps screenshot(s)"
echo
