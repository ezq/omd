FROM debian:8
MAINTAINER Ezequiel M. Cardinali<ezequiel.caridnali@surhive.com>
EXPOSE 80 443 22 4730 5666

ENV OMD_VERSION=v2.90

#### user environment ######################################
ENV HOME=/root
WORKDIR $HOME
ADD ./scripts/start.sh $HOME
RUN chmod +x $HOME/start.sh
ADD ./files/.screenrc $HOME

### OMD installation ######################################
ADD ./scripts/install_*.sh $HOME/
RUN chmod +x $HOME/install_*.sh
RUN $HOME/install_common.sh
RUN $HOME/install_omd.sh
RUN mkdir -p /etc/nagios3/
ADD ./files/zuliprc /etc/nagios3/
ADD ./files/update-exim4.conf.conf /etc/exim4/
ADD ./files/cpu_load.include /opt/omd/versions/default/share/check_mk/checks/

#### Mount point space requirements (MB)
ARG VOL_ETC_MB_MIN
ARG VOL_LOCAL_MB_MIN
ARG VOL_VAR_MB_MIN

ENV VOL_ETC_MB_MIN=$VOL_ETC_MB_MIN
ENV VOL_LOCAL_MB_MIN=$VOL_LOCAL_MB_MIN
ENV VOL_VAR_MB_MIN=$VOL_VAR_MB_MIN

ARG SITENAME
ENV SITENAME=$SITENAME
RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS
ARG OMDPASSWORD
ENV OMDPASSWORD=$OMDPASSWORD

ENV APACHE_CMD="exec /usr/sbin/apache2ctl -D FOREGROUND"

CMD ["/root/start.sh"]
