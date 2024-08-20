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
- SRS is primarily designed to be ran inside a Screen session for better productivity
- I run a check to see what ISP owns the IPs that are about to be port scanned. This not only helps to prevent false positives (Cloudflare has every port open), but it also stops time being wasted on things like WAFs and shared hosting. More can be added on line `195` using `; /*HOST*/Id`
- Subzy fingerprints for some targets are broken, leading to false positives. SRS will check if the fingerprints file exists and if the broken ones are in the fingerprints. If it is, it will remove that section.
- Ubuntu installs certain packages through Snap, including Chromium. The Chrome runners for that are about 11MB each which can easily fill up your disk. Additionally, some screenshots will be skipped. I recommend downloading the latest binary yourself with the link for Chromium itself above. Change the Chrome paths to your binary on line `41`. The non-Snap runners only take about 12-16KB each and don't require privileges to delete the folders.
- If you're using the Snap version, run [srs-snap.sh](https://github.com/felention/SRS/blob/main/srs-snap.sh) instead. This will split the files for GoWitness into 250 lines making it a total of 5.5GB (This is because GoWitness does both http and https unless specified).
- Running `./srs.sh hash` will produce a SHA1 hash of the script. The current hash is: `6939f839ce138ecfd703ff3fae144c3e122cf521`

## Required
**Adding the below to your sudoers file.**
- `*USER* ALL=(ALL:ALL) NOPASSWD: /usr/bin/masscan` - Masscan uses it's own networking stack making it always require root/sudo. Feel free to swap this out for your own port scanner, but do keep in mind to change the way the output is parsed.
#### If using srs-snap
- `*USER* ALL=(ALL) NOPASSWD: /bin/rm -rf /tmp/snap-private-tmp/snap.chromium/tmp/chromedp-runner*/` - As it requires permissions to delete the snap temporary folders, this will be ran after every 250 runs of GoWitness to prevent the disk from filling up.

## Problems
- If you're using Chromium Snap, there will be issues with GoWitness not taking screenshots for certain subdomains, therefore leaving out valid targets. This can be fixed by using the latest binary from [Chromium.org](https://www.chromium.org/).

## To be added
- Web interface - This is so you can quickly check without connecting to your box. This will be another .sh file (hopefully) that will be executed so it's a choice.
- Replace Subzy
- Whois - This will check if a domain exists before starting SRS. This is just in-case there is a typo when typing in the target.
- States - States will allow you to continue where you left off if you're performing SRS outside of a screen session, or if there is an abrupt end, such as a crash.
- Debugging - All this will do is save the whole output into a separate file. It will also save backups of files before they are overwritten or removed.
