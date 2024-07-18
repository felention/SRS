#!/bin/bash

### Print own hash value
if [[ "${1,,}" =~ ^(h|hash)$ ]]; then
    echo "SHA1 for this file is $(sha1sum $0 | awk '{print $1}')"
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
cbp="$HOME/chromium/chromium"

### Subfinder
echo "Starting Subfinder..."
subfinder -all -o "subfinder.txt" -ip -active -d "$1"
cat "subfinder.txt" | sed 's/,.*//g' > subdomains.txt
cat "subfinder.txt" | awk -F ',' '{print $2}' > ips.txt
subs="$(cat subdomains.txt | wc -l)"
rm subfinder.txt

### crtsh
echo "Starting crtsh..."
crtc=0
curl -s "https://crt.sh/?q=%25.$1&output=json" > crt.txt
while [[ -z "$(grep "$1" crt.txt)" && -n "$(grep "error\|\[]\|502 Bad Gateway" crt.txt)" ]]; do
    sleep 5
    curl -s "https://crt.sh/?q=%25.$1&output=json" > crt.txt
    crtc=$((crtc+1))
    if [[ $crtc -eq 5 ]]; then
        echo "Skipping crtsh due to too many errors"
        rm crt.txt
        crtf=1
        break
    fi
done
if [[ $crtf -ne 1 ]]; then
    jq -r '.[].common_name' crt.txt > crt2.txt
    jq -r '.[].name_value' crt.txt >> crt2.txt
    sed -i '/*/d' crt2.txt
    grep "$1" crt2.txt > crt.txt
    awk -i inplace '!a[$0]++' crt.txt
    crts="$(cat crt.txt | wc -l)"
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
gowitness file -X 1920 -Y 1080 -F -f "../subdomains.txt" --chrome-path "$cbp"
gowitness report export -f "report.zip"
unzip "report.zip"
mv "gowitness" "Report"
rm -rf "report.zip" /tmp/chromedp-runner*
cd ..

### Subzy Fingerprint Check
echo "Starting Subzy Fingerprint Check..."
sfl="$HOME/subzy/fingerprints.json"
if [[ ! -f "$sfl" ]]; then
    subzy update
fi
if [[ -n "$(grep "Akamai" $sfl)" ]]; then
    sfs="$(grep -n "Akamai" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi
if [[ -n "$(grep "Firebase" $sfl)" ]]; then
    sfs="$(grep -n "Firebase" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi
if [[ -n "$(grep "Instapage" $sfl)" ]]; then
    sfs="$(grep -n "Instapage" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi
if [[ -n "$(grep "Gitlab" $sfl)" ]]; then
    sfs="$(grep -n "Gitlab" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi
if [[ -n "$(grep "Key CDN" $sfl)" ]]; then
    sfs="$(grep -n "Key CDN" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi
if [[ -n "$(grep "Sendgrid" $sfl)" ]]; then
    sfs="$(grep -n "Sendgrid" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi
if [[ -n "$(grep "Smugsmug" $sfl)" ]]; then
    sfs="$(grep -n "Smugsmug" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi
if [[ -n "$(grep "Squarespace" $sfl)" ]]; then
    sfs="$(grep -n "Squarespace" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi
if [[ -n "$(grep "WP Engine" $sfl)" ]]; then
    sfs="$(grep -n "WP Engine" $sfl | sed 's/^\([0-9]*\):.*/\1/')"
    sfe=$((sfs+8))
    sfs=$((sfs-1))
    sed -i "${sfs},${sfe}d" $sfl
fi

### Subzy
echo "Starting Subzy..."
subzy r --output "subzy.txt" --targets "subdomains.txt" --vuln
if [[ "$(cat "subzy.txt")" == "null" ]]; then
    rm "subzy.txt"
fi
subzy r --https --output "subzy-ssl.txt" --targets "subdomains.txt" --vuln
if [[ "$(cat "subzy-ssl.txt")" == "null" ]]; then
    rm "subzy-ssl.txt"
fi

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
    ispi="$(cat scan.txt | wc -l)"
    masi="$(cat ports.txt | wc -l)"

    ### Port Parse
    echo "Starting Port Parse..."
    sed -i '/state="open"/!d' ports.txt
    sed -i 's/.*addr="//g; s/" addr.*portid="/:/g; s/".*//g' ports.txt
    awk -i inplace '!a[$0]++' ports.txt
else
    echo "Skipping Masscan and Port Parse as IPs aren't useful."
fi
rm scan.txt

if [[ -f ports.txt && -s ports.txt ]]; then
    ### GoWitness Ports
    echo "Starting GoWitness Ports..."
    mkdir "GoWitness-Ports" && cd "$_"
    gowitness file -X 1920 -Y 1080 -F -f "../ports.txt" --chrome-path "$cbp"
    gowitness report export -f "report.zip"
    unzip "report.zip"
    mv "gowitness" "Report"
    rm -rf "report.zip" /tmp/chromedp-runner*
    cd ..
else
    echo "Skipping GoWitness Ports as there are no open ports or useful IPs."
    if [[ ! -s ports.txt ]]; then
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
echo "$masi open port(s) from $ispi IP address(es)"
echo
