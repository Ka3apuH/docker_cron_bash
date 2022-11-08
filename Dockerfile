FROM ubuntu:latest as base

ARG MINIO_HTTP=""
ARG ACCESS_KEY=""
ARG SECRET_KEY=""
ARG CRON_STR="0 4 * * *"

RUN  \
apt-get update && \
apt-get install -y cron wget postgresql-client rsyslog && \ 
#ссылку иногда нужно менять.... если выйдет ошибка 
wget https://dl.min.io/client/mc/release/linux-amd64/mcli_20221107234739.0.0_amd64.deb && \
dpkg -i mcli_20221107234739.0.0_amd64.deb && \
rm mcli_20221107234739.0.0_amd64.deb && \
mcli alias set myminio ${MINIO_HTTP} ${ACCESS_KEY} ${SECRET_KEY}

FROM base as cron_job_backup

ADD src/backup.sh backup.sh

RUN chmod +x backup.sh

RUN crontab -l | { cat; echo "$CRON_STR /backup.sh 2>&1 | logger -t mycmd"; } | crontab -

RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf
CMD printenv | sed 's/^\(.*\)$/export \1/g' > /project_env.sh && \
 service cron start && rsyslogd -n && tail -f /var/log/syslog
