# SRS
Simple Recon Script is a simple bash script designed to perform reconnaissance on websites to aid primarily in web application based security research.

## Used tools
[Subfinder](https://github.com/projectdiscovery/subfinder)\
[crt.sh](https://crt.sh/)\
[GoWitness](https://github.com/sensepost/gowitness)\
[Subzy](https://github.com/PentestPad/subzy)\
[Masscan](https://github.com/robertdavidgraham/masscan)\
[jq](https://github.com/jqlang/jq)\
[Chromium](https://download-chromium.appspot.com/?platform=Linux_x64&type=snapshots)

## Developed on
Ubuntu 20.04\
Subfinder 2.6.3\
GoWitness 2.5.1\
Subzy 1.1.0\
Masscan 1.0.5\
jq 1.6\
Chromium 128.0.6574.0

## Notes
- This relies on you to set up the required tools
- SRS is primarily designed to be run in a Screen session for better productivity
- I run a check to see what ISP owns the IPs that are about to be port scanned. This not only helps to prevent false positives (Cloudflare has every port open), but it also stops time being wasted on things like WAFs and shared hosting. More can be added on line `114` using `; /*HOST*/Id`
- For some reason, Subzy is adamant about having its own home folder to store it's fingerprints instead of just using the original it copies it from. I do remove the folder after Subzy finishes, but it can be kept by removing line `99`
- Ubuntu installs certain packages through Snap, including Chromium. The Chrome runners for that are about 11MB each which can easily fill up your disk. Additionally, some screenshots will be skipped. I recommend downloading the latest binary yourself with the link for Chromium itself above. Change the Chrome paths to your binary on lines `67` & `141`. The non-Snap runners only take about 12-16KB each and don't require privileges to delete the folders.
- If you're using the Snap version, run [srs-snap.sh](https://github.com/felention/SRS/blob/main/srs-snap.sh) instead. This will split the files for GoWitness into 250 lines making it a total of 5.5GB (This is because GoWitness does both http and https unless specified).

## Required
**Adding the below to your sudoers file.**
- `*USER* ALL=(ALL:ALL) NOPASSWD: /usr/bin/masscan` - Masscan uses it's own networking stack making it always require root/sudo. Feel free to swap this out for your own port scanner, but do keep in mind to change the way the output is parsed.
#### If using srs-snap
- `*USER* ALL=(ALL) NOPASSWD: /bin/rm -rf /tmp/snap-private-tmp/snap.chromium/tmp/chromedp-runner*/` - As it requires permissions to delete the snap temporary folders, this will be ran after every 250 runs of GoWitness to prevent the disk from filling up.

## Problems
- If you're using Chromium Snap, there will be issues with GoWitness not taking screenshots, therefore leaving out valid targets. This can be fixed by using the latest binary from [Chromium.org](https://www.chromium.org/).
- Subzy seems to be getting false positives on Akamai. 

## To be added
- Whois - This will check if a domain exists before starting SRS. This is just in-case there is a typo when typing in the target.
- States - States will allow you to continue where you left off if you're performing SRS outside of a screen session, or if there is an abrupt end, such as a crash.
- Debugging - All this will do is save the whole output into a separate file. It will also save backups of files before they are overwritten or removed.
