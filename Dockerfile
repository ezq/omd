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

### -- OMD site creation (DEMO) ##############################
ARG SITENAME=monitoring
ENV SITENAME=$SITENAME
RUN echo "export SITENAME=$SITENAME" > .sitename.env
RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS
RUN echo "create OMD site: $SITENAME" && omd create -u 1000 -g 1000 $SITENAME || true

# -- ONBUILD
# when used as a base image, this instructions trigger the creation of another site if NEW_SITENAME is not `demo`
ONBUILD ARG NEW_SITENAME=monitoring
ONBUILD ENV NEW_SITENAME=$NEW_SITENAME
ONBUILD RUN [ "$NEW_SITENAME" != "demo" ] && echo "export SITENAME=$NEW_SITENAME" > .sitename.env && echo "CREATE new site:$NEW_SITENAME" && omd -f rm $SITENAME && omd create -u 1001 -g 1001 $NEW_SITENAME || true

ENV APACHE_CMD="exec /usr/sbin/apache2ctl -D FOREGROUND"

CMD ["/root/start.sh"]
