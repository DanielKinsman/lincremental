lincremental - an incremental backup system using rsync
=======================================================

Lincremental is heavily based on [Mike Rubel's guide](http://www.mikerubel.org/computers/rsync_snapshots/). It is easily configurable, you can set the number of hourly/daily/weekly/monthly backups to keep, as well as automatically keeping all the backup sets in sync with a server via rysnc daemon or ssh. Lincremental doesn't however make the backup sets "as read only as possible" (none of the mounting / unmounting that Rubel does) so make sure not to mess them up. I don't have any users apart from myself so I don't have to worry about that too much (famous last words).

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

amazon glacier backups
----------------------
Lincremental can also backup to amazon's [glacier service](https://aws.amazon.com/glacier/). At the moment this does *not* mean incremental backups, but rather uploading a copy of the latest daily backup every 28 days (configurable). While these uploads are only initiated once every 28 days (configurable), they are resumed automatically every hour until they are complete.

Use this feature at your own risk, I am not liable for any charges you incurr from amazon (or anywhere else for that matter).

Steps to install:

. install lincremental as above
. download, install and configure [glacier-cmd](https://github.com/uskudnik/amazon-glacier-cmd-interface) and test that it is working (for root user)
. set the appropriate "AWS" options in /etc/lincremental/lincremental.cfg
. if you want your files to be encrypted before being uploaded to amazon (recommended), configure [GnuPG](http://gnupg.org/) and provide the appropriate key in /etc/lincremental/lincremental.cfg (GPG_PUBLIC_KEY)

Note that when using encryption, you must backup your GnuPG private keys to somewhere manually rather than relying on lincremental and amazon glacier. If you lose the private keys in a hard drive crash, the encrypted backups on glacier will be useless.

Contact
-------

danielkinsman+lincremental@gmail.com ([gpg key](http://sks.spodhuis.org/pks/lookup?op=vindex&search=0x709C423C750B8627))