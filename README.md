# SRS
Simple Recon Script is a simple bash script designed to perform reconnaissance on websites to aid primarily in web application based security research.

## Used tools
[Subfinder](https://github.com/projectdiscovery/subfinder)\
[crt.sh](https://crt.sh/)\
[GoWitness](https://github.com/sensepost/gowitness)\
[Masscan](https://github.com/robertdavidgraham/masscan)\
[Chromium](https://download-chromium.appspot.com/?platform=Linux_x64&type=snapshots)

## Developed on
Ubuntu 20.04\
Subfinder 2.6.7\
GoWitness 3.0.5\
Masscan 1.0.5\
Chromium 133.0.6836.0

## Notes
- This relies on you to set up the required tools.
- SRS is primarily designed to be ran inside a Screen session for better productivity. This also prevents session drops from ending the process.
- The Chromium binary location can be changed on line `47`. This is just the better option overall, especially on Ubuntu thanks to Snap. `--chrome-path "$cbp"` can be removed on other distros if Chromium/Chrome is installed via the package manager, but this is untested and could fail.
- This is not advised to use on Ubuntu 23.10 or above thanks to restricted unprivileged user namespaces. This is just to shave down setup time and configuration system side.
- This runs a check to see what ISP owns the IPs that are about to be port scanned. This not only helps to prevent false positives (Cloudflare has every port open), but it also stops time being wasted on things like WAFs and shared hosting. More can be added on line `130` using `; /*HOST*/Id`.
- Running `./srs.sh v` will output the current version. It will then check for a new version.

## Required
**Adding the below to your sudoers file.**
- `*USER* ALL=(ALL:ALL) NOPASSWD: /usr/bin/masscan` - Masscan uses it's own networking stack making it always require root/sudo. Feel free to swap this out for your own port scanner, but do keep in mind to change the way the output is parsed.

## To be added
- Web interface - This is so you can quickly check without connecting to your box. This will be another .sh file (hopefully) that will be executed so it's a choice through modularity.
- Find or create a better subdomain takeover tool.
- Whois - This will check if a domain exists before starting SRS. This is just in-case there is a typo when typing in the target.
- States - States will allow you to continue where you left off if you're performing SRS outside of a screen session, or if there is an abrupt end, such as a crash.
- Debugging - All this will do is save the whole output into a separate file. It will also save backups of files before they are overwritten or removed.
