#!/usr/bin/env bash
export OMD_ROOT=/opt/omd/sites/$SITENAME
source /root/.sitename.env


echo "Config and start OMD site: $SITENAME"
echo "--------------------------------------"

trap "omd stop $SITENAME; exit 0" SIGKILL SIGTERM SIGHUP SIGINT

# mounts empty => sync dirs in mounts        / lsyncd dir->mount
# mounts not empty => sync mounts in dirs    / lsyncd dir->mount
# no mounts => do nothing                    / no lsyncd

echo "Checking for volume mounts..."
echo "--------------------------------------"
for dir in "local" "etc" "var"; do
  d_local="$OMD_ROOT/$dir"
  d_mount="$OMD_ROOT/${dir}.mount"
  if [ ! -d "$d_mount" ]; then
    # no volume mount
    echo " * $dir/: [No Volume]"
  else
    # volume mount exists
    echo " * $dir/: [EXTERNAL Volume] at $d_mount"
    if su - $SITENAME -c "test -w '$d_mount'" ; then
        echo "   * mounted volume is writable"
    else
        echo "   * ERROR: Mounted volume is not writeable: $d_mount" && exit -1
    fi
    if [ ! "$(ls -A $d_mount)" ]; then
        # mount is empty => sync dir in mount
        echo "   => $dir.mount is empty; initial sync from local $dir ..."
        su - $SITENAME -c "rsync -rlptD --quiet $d_local/ $d_mount"
        [ $? -gt 0 ] && echo "ERROR: sync $d_local -> $d_mount!" && exit -1
    else
        # mount contains data => sync mount in dir
        echo "   <= Volume contains data; sync into local $dir ..."
        su - $SITENAME -c "rsync -rlptD --quiet $d_mount/ $d_local"
        [ $? -gt 0 ] && echo "ERROR: sync $d_mount -> $d_local" && exit -1
    fi
    echo "   * writing the lsyncd config for $dir.mount..."
    cat >>$OMD_ROOT/.lsyncd <<EOF
sync {
   default.rsync,
   source = "${d_local}/",
   target = "${d_mount}",
   delay  = 0
}
EOF
    chown $SITENAME:$SITENAME $OMD_ROOT/.lsyncd
  fi
done

echo

if [ -f $OMD_ROOT/.lsyncd ]; then
  echo "lsyncd: writing the global settings..."
  cat >>$OMD_ROOT/.lsyncd <<EOF
settings {
   statusFile  = "$OMD_ROOT/.lsyncd_status",
   inotifyMode = "CloseWrite or Modify"
}
EOF

  echo "lsyncd: Starting  ..."
  echo "--------------------------------------"
  su - $SITENAME -c 'lsyncd ~/.lsyncd'
fi

if [ ! -z "${OMD_SMARTHOST}" ]; then
  echo "configuring smarthost..."
  mv /root/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
  sed -i "s/OMD_HOSTNAME/$OMD_HOSTNAME/g" /etc/exim4/update-exim4.conf.conf
  sed -i "s/OMD_EXIM_DOMAIN/$OMD_EXIM_DOMAIN/g" /etc/exim4/update-exim4.conf.conf
  sed -i "s/OMD_SMARTHOST/$OMD_SMARTHOST/g" /etc/exim4/update-exim4.conf.conf
  update-exim4.conf
fi
echo
echo "configuring zulip nagios plugin..."
sed -i "s/OMD_ZULIP_EMAIL/$OMD_ZULIP_EMAIL/g" /etc/nagios3/zuliprc
sed -i "s/OMD_ZULIP_KEY/$OMD_ZULIP_KEY/g" /etc/nagios3/zuliprc
sed -i "s/OMD_ZULIP_SITE/$OMD_ZULIP_SITE/g" /etc/nagios3/zuliprc

echo

echo "crond: Starting ..."
echo "--------------------------------------"
test -x /usr/sbin/crond && /usr/sbin/crond
test -x /usr/sbin/cron  && /usr/sbin/cron

echo

# Fix naemon Pending service checks
#sed -i '/^check_result_path/ s/naemon/nagios/' /omd/sites/$SITENAME/etc/naemon/naemon.d/omd.cfg

omd config ${SITENAME} set CORE nagios
omd config ${SITENAME} set THRUK_COOKIE_AUTH off
omd config ${SITENAME} set PNP4NAGIOS off
omd config ${SITENAME} set GRAFANA on
omd config ${SITENAME} set INFLUXDB on
omd config ${SITENAME} set NAGFLUX on
omd config ${SITENAME} set INFLUXDB_HTTP_TCP_PORT 0.0.0.0:8086

sed -i '/default_theme/ s/Thruk2/EONFlatDark/g' /omd/sites/${SITENAME}/etc/thruk/thruk.conf
sed -i "/action_url/ s/SITENAME/${SITENAME}/g" /omd/sites/${SITENAME}/etc/core/conf.d/check_mk_templates.cfg

echo "omd-labs: Starting site $SITENAME..."
echo "--------------------------------------"
sudo su - $SITENAME -c "set_admin_password $OMDPASSWORD"
omd start $SITENAME

echo

echo "omd-labs: Starting Apache web server..."
echo "--------------------------------------"

$APACHE_CMD &

wait
