lincremental - an incremental backup system using rsync
-------------------------------------------------------

Lincremental is heavily based on [Mike Rubel's guide](http://www.mikerubel.org/computers/rsync_snapshots/). It easily configurable, you can set the number of hourly/daily/weekly/monthly backups to keep, as well as automatically keeping all the backup sets in sync with a server via rysnc daemon or ssh. Lincremental doesn't however make the backup sets "as read only as possible" (none of the mounting / unmounting that Rubel does) so make sure not to mess them up. I don't have any users apart from myself so I don't have to worry about that too much (famous last words).

It will only backup a single directory (e.g. `/home/.ecryptfs`) as specified in `lincremental.cfg`.

Steps to install:

1. set the appropriate parameters in `lincremental.cfg`
2. `mkdir /etc/lincremental`
3. `mv lincremental.cfg /etc/lincremental/`
4. `mkdir /usr/local/lincremental`
5. `mv lincremental_* /usr/local/lincremental/`
6. `/usr/local/lincremental/lincremental_initial.sh`
7. `/usr/local/lincremental/lincremental_network.sh` (optional)
8. `ln -s /usr/local/lincremental/lincremental_hourly.sh  /etc/cron.hourly/lincremental`
9. `ln -s /usr/local/lincremental/lincremental_daily.sh   /etc/cron.daily/lincremental`
10. `ln -s /usr/local/lincremental/lincremental_weekly.sh  /etc/cron.weekly/lincremental`
11. `ln -s /usr/local/lincremental/lincremental_monthly.sh /etc/cron.monthly/lincremental`
12. `ln -s /usr/local/lincremental/lincremental_network.sh /etc/cron.hourly/lincremental_network` (optional)

Contact danielkinsman+lincremental@gmail.com ([gpg key](http://sks.spodhuis.org/pks/lookup?op=vindex&search=0x709C423C750B8627))