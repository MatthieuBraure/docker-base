FROM phusion/baseimage:0.9.17
MAINTAINER Tom Nussbaumer <thomas.nussbaumer@gmx.net>

## install tool remapuser
COPY remapuser /sbin/

## Create a normal user 
RUN addgroup --gid 9999 app && \
adduser --uid 9999 --gid 9999 \
        --disabled-password --gecos "Standard User" app && \
usermod -L app && \
mkdir -p /home/app/.ssh && \
chmod 700 /home/app/.ssh && \
chown app:app /home/app/.ssh

CMD ["/sbin/my_init"]
