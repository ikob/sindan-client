#
# README
#

# required packages
 uuid-runtime (for uuidgen)
 wireless-tools (for iwgetid, iwconfig)
 ndisc6 (for rdisc6)
 dnsutils (for dig)
 curl (for curl)
 chromium-browser, npm (for nodejs)

# required node packages
 puppeteer-core
 speedline

# crontab
*/5 * * * * root cd <sindan_linux directory> && ./sindan.sh 1>/dev/null 2>/dev/null
*/3 * * * * root cd <sindan_linux directory> && ./sendlog.sh 1>/dev/null 2>/dev/null

