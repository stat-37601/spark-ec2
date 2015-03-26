#!/bin/bash

BIN_FOLDER="/root/spark/sbin"

if [[ "0.7.3 0.8.0 0.8.1" =~ $SPARK_VERSION ]]; then
  BIN_FOLDER="/root/spark/bin"
fi

# Copy the slaves to spark conf
cp /root/spark-ec2/slaves /root/spark/conf/
/root/spark-ec2/copy-dir /root/spark/conf

# Set cluster-url to standalone master
echo "spark://""`cat /root/spark-ec2/masters`"":7077" > /root/spark-ec2/cluster-url
/root/spark-ec2/copy-dir /root/spark-ec2

# The Spark master seems to take time to start and workers crash if
# they start before the master. So start the master first, sleep and then start
# workers.

# Stop anything that is running
$BIN_FOLDER/stop-all.sh

sleep 2

# Start Master
$BIN_FOLDER/start-master.sh

# Pause
sleep 20

# Start Workers
$BIN_FOLDER/start-slaves.sh

# Launch IPython on Spark startup.
mkdir -p /root/notebooks
cat > /root/spark-ec2/ipython-runner.sh <<EOF
#!/bin/bash

mkdir -p ~/notebooks
cd ~/notebooks
. ~/spark-ec2/ec2-variables.sh

export PYSPARK_DRIVER_PYTHON="$(which python27)"
export PYSPARK_DRIVER_PYTHON_OPTS="-m IPython --port=8080 --ip=0.0.0.0"

while true; do
  ~/spark/bin/pyspark
  sleep 2
done

EOF

chmod +x ~/spark-ec2/ipython-runner.sh
(~/spark-ec2/ipython-runner.sh &>ipython-runner.log &) &