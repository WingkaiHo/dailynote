FROM ubuntu:16.04

RUN apt-get update && \
apt-get install -y --no-install-recommends cron

# copy your cron file to / 
# the cron file like this  */1 * * * * your-script.sh param1 param2
# COPY your-cron /

# update the cron
# RUN crontab /your-cron

# copy your script to /usr/bin/
# COPY your-script.sh /usr/bin

CMD ["cron", "-f"]
RUN apt-get clean
RUN sed -i -e '/pam_loginuid.so/s/^/#/' /etc/pam.d/cron
