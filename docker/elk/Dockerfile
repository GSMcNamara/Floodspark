FROM floodspark/elk:v27
RUN apt-get install -y expect
COPY src/logstash-conf/* /etc/logstash/conf.d/
COPY password-setup.exp /
RUN chmod +x /password-setup.exp
COPY password-setup.sh /
RUN chmod +x /password-setup.sh
