FROM floodspark/p0f:v2
ENV int="eth0"
#ENV int="[interface here]"
USER root
ENTRYPOINT /opt/p0f/p0f -i $int -o /tmp/p0f/p0f.log
