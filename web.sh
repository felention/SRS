#!/bin/bash

### Set base location
out="$HOME/srs/web"
outp="$out/index.html"
wwd="$out/wwd.sh"

### Web Interface port
wip=10101

update() {
    sed -i "s|pre.*pre|pre>$(date)</pre|" "$outp"
}

if [[ "$1" == "start" ]]; then
    if [[ ! -f "$out/.com" && -f "$out/web.pid" ]]; then
        kill "$(cat "$out/web.pid")"
        rm "$out/web.pid"
    fi
    target="$2"
    debug="$3"
    python3 -m http.server "$wip" -d "$out" >/dev/null 2>&1 & echo "$!" > "$out/web.pid"

    ### Create Web Interface page
    if [[ ! -f "$outp" || "$(sha256sum "$outp")" != "47e93ca11666de21268916c1651db5b8d8508a42437883bbecabe6f0b7b8eca0" ]]; then
        cat <<-EOF > "$outp"
			<html>
			<head>
			  <title>SRSWI - ¦¦target¦¦</title>
			  <meta charset="UTF-8">
			  <link rel="icon" type="image/svg+xml" href="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPHN2ZyB3aWR0aD0iODAwcHgiIGhlaWdodD0iODAwcHgiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cGF0aCBkPSJNNCAxOEwyMCAxOCIgc3Ryb2tlPSIjMDAwMDAwIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik00IDEyTDIwIDEyIiBzdHJva2U9IiMwMDAwMDAiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIi8+CiAgPHBhdGggZD0iTTQgNkwyMCA2IiBzdHJva2U9IiMwMDAwMDAiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIi8+Cjwvc3ZnPg==">
			  <meta http-equiv="refresh" content="10">
			  <style>
			    body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;background-color:#1e1e1e;color:#f0f0f0}
			    h1{padding-bottom:2rem}
			    h3{margin:1rem}
			    h4{margin-top:5rem}
			    p{font-weight: bold;}
			    #body {text-align:center}
			    .crash {display:none;padding:0}
			    [id$="r"] span:before{content: "Waiting";color:#FF3B30}
			    [id$="o"] span:before{content: "Skipped";color:#FF9500}
			    [id$="a"] span:before{content: "Running";color:#FFD700}
			    [id$="g"] span:before{content: "Complete";color:#00FF66}
			    #r {color:#FF3B30}
			    #g {color:#00FF66}
			  </style>
			</head>
			<body>
			  <h3>Debugging - <span id="r">Disabled</span></h3>
			  <div id="body">
			    <h1>¦¦target¦¦</h1>
			    <p>Welcome to the SRS Web Interface. Here, you can see where the current running stage for SRS is.</p>
			    <h1 class="crash" id="r">SRS CRASHED</h1>
			    <h3 id="s1r">Subfinder - <span></span></h3>
			    <h3 id="s2r">crt.sh - <span></span></h3>
			    <h3 id="s3r">GoWitness Subdomains - <span></span></h3>
			    <h3 id="s4r">ISP Check - <span></span></h3>
			    <h3 id="s5r">Masscan - <span></span></h3>
			    <h3 id="s6r">GoWitness Ports - <span></span></h3>
			    <h3 id="s7r">Archiving - <span></span></h3>
			    <h4>Last updated at: <pre></pre></h4>
			  </div>
			</body>
			</html>
		EOF
    fi

    ### Create Watchdog
    if [[ ! -f "$wwd" ]]; then
        cat <<-'EOF' > "$wwd"
			#!/bin/bash

			### Set vars
			out="$HOME/srs/web"
			sid="$out/srs.pid"
			web="$out/../web.sh"
			pid="$(cat "$sid")"

			while [[ -n "$(ps -p "$pid" | grep srs.sh)" ]]; do
			  sleep 60
			done

			if [[ ! -f "$out/.com" ]]; then
			  bash "$web" crash
			fi
		EOF
    fi

    bash "$wwd" >/dev/null 2>&1 &

    if [[ "$3" == 1 ]]; then
        sed -i 's/r">Dis/g">En/' "$outp"
    fi
    sed -i "s/¦¦target¦¦/$2/" "$outp"
    update
elif [[ "$1" == "crash" ]]; then
    sed -i 's/none/visible/' "$outp"
    update
    rm "$out/srs.pid"
elif [[ "$1" == 1 ]]; then
    sed -i 's/s1r/s1a/' "$outp"
    update
elif [[ "$1" == 2 ]]; then
    sed -i 's/s1a/s1g/;s/s2r/s2a/' "$outp"
    update
elif [[ "$1" == 3 ]]; then
    sed -i 's/s2a/s2g/;s/s3r/s3a/' "$outp"
    update
elif [[ "$1" == 4 ]]; then
    sed -i 's/s3a/s3g/;s/s4r/s4a/' "$outp"
    update
elif [[ "$1" == 5 && "$2" == 1 ]]; then
    sed -i 's/s4a/s4g/;s/s5r/s5s/' "$outp"
    update
elif [[ "$1" == 5 ]]; then
    sed -i 's/s4a/s4g/;s/s5r/s5a/' "$outp"
    update
elif [[ "$1" == 6 && "$2" == 1 ]]; then
    sed -i 's/s5a/s5g/;s/s6r/s6s/' "$outp" 
    update
elif [[ "$1" == 6 ]]; then
    sed -i 's/s5a/s5g/;s/s6r/s6a/' "$outp"
    update
elif [[ "$1" == 7 ]]; then
    sed -i 's/s6a/s6g/;s/s7r/s7a/' "$outp"
    update
elif [[ "$1" == 8 ]]; then
    sed -i 's/s7a/s7g/' "$outp"
    update
    touch "$out/.com"
    rm -f "$out/srs.pid"
elif [[ "$1" == "stop" ]]; then
    kill "$(cat "$out/web.pid")"
    rm -f "$out/web.pid" "$out/.com" "$out/index.html"
fi