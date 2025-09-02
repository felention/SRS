#!/bin/bash

### Print version and check for new version
if [[ "${1,,}" =~ ^(v|version)$ ]]; then
    cvr='2'
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
elif [[ -z "$(dig +short SOA "$1")" ]]; then
    echo "Domain unresolvable. Either the domain has no SOA or is unregistered."
    exit
fi

### Set tool and target location
out="$HOME/srs"
tout="$out/$1"
run="$out/web.sh"
runl="$out/web"

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

### Enable debugging
if [[ "${2,,}" =~ ^(d|debug)$ ]]; then
    dbg=1
    echo "Debugging enabled."
    mkdir "debug"
    exec > >(tee -ia debug/terminal.txt) 2>&1
fi

### Check if Web Interface script exists for later
if [[ -f "$run" ]]; then
    web=1
    mkdir -p "$runl"
    echo "$$" > "$runl/srs.pid"
    if [[ "$dbg" == 1 ]]; then
        bash "$run" start "$1" 1
    else
        bash "$run" start "$1"
    fi
fi

### Subfinder
echo "Starting Subfinder..."
if [[ "$web" == 1 ]]; then
    bash "$run" 1
fi
subfinder -all -o subfinder.txt -ip -active -d "$1"
cat subfinder.txt | sed 's/,.*//g' > subdomains.txt
cat subfinder.txt | awk -F ',' '{print $2}' > ips.txt
subs="$(wc -l < subdomains.txt)"
if [[ "$dbg" == 1 ]]; then
    cp subfinder.txt debug/
fi
rm subfinder.txt

### crtsh
echo "Starting crtsh..."
if [[ "$web" == 1 ]]; then
    bash "$run" 2
fi
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
    if [[ "$dbg" == 1 ]]; then
        cp crt.txt debug/
    fi
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
if [[ "$web" == 1 ]]; then
    bash "$run" 3
fi
mkdir "GoWitness-Subdomains" && cd "$_"
gowitness scan file -f ../subdomains.txt --chrome-path "$cbp" --driver gorod --write-db --screenshot-fullpage -T 20 --log-scan-errors
gwss="$(find screenshots/ -maxdepth 1 -type f | wc -l)"
gowitness report generate --zip-name report.zip
unzip -q report.zip -d "Report"
if [[ "$dbg" == 1 ]]; then
    cp report.zip ../debug/GWS_report.zip
fi
rm -rf report.zip /tmp/leakless-amd64-* /tmp/gowitness-v3-gorod-* /tmp/.org.chromium.Chromium.*
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
if [[ "$web" == 1 ]]; then
    bash "$run" 4
fi
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
    if [[ "$web" == 1 ]]; then
        bash "$run" 5
    fi
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
    if [[ "$web" == 1 ]]; then
        bash "$run" 5 1
    fi
    ipsi=0
    masi=0
fi
rm scan.txt

if [[ -s ports.txt ]]; then
    ### GoWitness Ports
    echo "Starting GoWitness Ports..."
    if [[ "$web" == 1 ]]; then
        bash "$run" 6
    fi
    mkdir "GoWitness-Ports" && cd "$_"
    gowitness scan file -f "../ports.txt" --chrome-path "$cbp" --driver gorod --write-db --screenshot-fullpage -T 20 --log-scan-errors
    gwps="$(find screenshots/ -maxdepth 1 -type f | wc -l)"
    gowitness report generate --zip-name "report.zip"
    unzip -q report.zip -d "Report"
    if [[ "$dbg" == 1 ]]; then
        cp report.zip ../debug/GWP_report.zip
    fi
    rm -rf report.zip /tmp/leakless-amd64-* /tmp/gowitness-v3-gorod-* /tmp/.org.chromium.Chromium.*
    cd ..
else
    echo "Skipping GoWitness Ports as there are no open ports or useful IPs."
    if [[ "$web" == 1 ]]; then
        bash "$run" 6 1
    fi
    gwps=0
    if [[ -e ports.txt ]]; then
        rm ports.txt
    fi
fi

### Archiving
echo "Starting Archiving..."
if [[ "$web" == 1 ]]; then
    bash "$run" 7
fi
cd ..
tar -zcvf "$1.tar.gz" "$1/"
if [[ "$web" == 1 ]]; then
    bash "$run" 8
fi
rm -rf "$1/" "$runl/srs.pid"

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
