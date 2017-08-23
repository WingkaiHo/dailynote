FROM centos:7
RUN yum -y install cronie && \
yum clean all

RUN sed -i -e '/pam_loginuid.so/s/^/#/' /etc/pam.d/crond

RUN chmod 0644 /etc/crontab


# copy your cron file to / 
# the cron file like this  */1 * * * * your-script.sh param1 param2
# COPY your-cron /

# update the cron
# RUN crontab /your-cron

# copy your script to /usr/bin/
# COPY your-script.sh /usr/bin

CMD ["crond", "-n"] 
