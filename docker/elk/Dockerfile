FROM floodspark/elk:v26
RUN apt-get install -y expect
COPY password-setup.exp /
RUN chmod +x /password-setup.exp
COPY password-setup.sh /
RUN chmod +x /password-setup.sh