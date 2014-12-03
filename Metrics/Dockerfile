FROM ubuntu:14.04
MAINTAINER Selenium <selenium-developers@googlegroups.com>

COPY entry_point.sh /opt/bin/entry_point.sh
RUN chmod +x /opt/bin/entry_point.sh

ENTRYPOINT ["/opt/bin/entry_point.sh"]
