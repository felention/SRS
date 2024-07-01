# SRS
Simple Recon Script is a simple bash script designed to perform reconnaissance on websites to aid primarily in web application based security research.

## Used tools
[Subfinder](https://github.com/projectdiscovery/subfinder)\
[crt.sh](https://crt.sh/)\
[GoWitness](https://github.com/sensepost/gowitness)\
[Subzy](https://github.com/PentestPad/subzy)\
[Masscan](https://github.com/robertdavidgraham/masscan)\
[jq](https://github.com/jqlang/jq)

## Developed on
Ubuntu 20.04\
Subfinder 2.6.3\
GoWitness 2.5.0\
Subzy 1.1.0\
Masscan 1.0.5\
jq 1.6

## Required
**Adding the below to your sudoers file.**
- `*USER* ALL=(ALL) NOPASSWD: /bin/rm -rf /tmp/snap-private-tmp/snap.chromium/tmp/chromedp-runner*/` - Ubuntu uses Snap to install certain packages such as Chromium. For some reason, the temporary Snap directory for the Chromium runner is not cleared, leaving multiple Chromium runners. This will easily fill up disk space unless dealt with, especially with larger targets. Feel free to adjust the script around line `75` & `160` as neccessary, this is just a precautionary measure.
- `*USER* ALL=(ALL:ALL) NOPASSWD: /usr/bin/masscan` - Masscan uses it's own networking stack making it always require root/sudo. Feel free to swap this out for your own port scanner, but do keep in mind to change the way the output is parsed.

## Notes
- This relies on you setting up the required tools
- SRS is primarily designed to be ran in a Screen session.
- I run a check to see what ISP owns the IPs that are about to be port scanned. This not only helps to prevent false positives (Cloudflare has every port open), but it also stops time being wasted on things like WAFs and shared hosting. More can be added on line `129` using `; /*HOST*/Id`
- For some reason, Subzy is adament on having it's own home folder to store it's fingerprints instead of just using the original it copies it from. I do remove the folder after Subzy finishes, but it can be kept by removing line `99`

## To be added
- Whois - This will check if a domain exists before proceeding. This is just in-case there is a typo when typing in the target.
- States - States will allow you to continue where you left off if you're performing SRS outside of a screen session, or if there is an abrupt end, such as a crash.
- Debugging - All this will do is save the whole output into a seperate file. It will also save backups of files before they are overwritten or removed.
