#!/bin/sh

export LANG=C
export LD_LIBRARY_PATH=/usr/local/lib64

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

CONFIG_PATH=/data/options.json
MQTT_HOST="$(jq --raw-output '.mqtt_host' $CONFIG_PATH)"
MQTT_USER="$(jq --raw-output '.mqtt_user' $CONFIG_PATH)"
MQTT_PASS="$(jq --raw-output '.mqtt_password' $CONFIG_PATH)"
MQTT_TOPIC="$(jq --raw-output '.mqtt_topic' $CONFIG_PATH)"
PROTOCOL="$(jq --raw-output '.protocol' $CONFIG_PATH)"
FREQUENCY="$(jq --raw-output '.frequency' $CONFIG_PATH)"
# GAIN="$(jq --raw-output '.gain' $CONFIG_PATH)"
# OFFSET="$(jq --raw-output '.frequency_offset' $CONFIG_PATH)"
DEVICEID="$(jq --raw-output '.deviceid' $CONFIG_PATH)"

# Start the listener and enter an endless loop
echo "Starting RTL_433 with parameters:"
echo "MQTT Host =" $MQTT_HOST
echo "MQTT User =" $MQTT_USER
echo "MQTT Password =" $MQTT_PASS
echo "MQTT Topic =" $MQTT_TOPIC
echo "RTL_433 Protocol =" $PROTOCOL
echo "RTL_433 Frequency =" $FREQUENCY
echo "RTL_433 DeviceID =" $DEVICEID

echo "MQTT Autodiscovery:"
AUTO_D="{\"topic\":\"$MQTT_TOPIC\",\"automation_type\":\"trigger\",\"type\":\"button_short_press\",\"subtype\":\"button_1\",\"device\":{\"identifiers\":\"Doorbell\",\"manufacturer\":\"KAKU\",\"model\":\"ACDB-7000A\",\"name\":\"Doorbell\"}}"
echo $AUTO_D;
echo $AUTO_D | /usr/bin/mosquitto_pub -h $MQTT_HOST -u $MQTT_USER -P $MQTT_PASS -i RTL_433 -r -l -t homeassistant/device_automation/$DEVICEID/power/config

/usr/local/bin/rtl_433 -F json -R $PROTOCOL -f $FREQUENCY | while read line

do
  DEVICEID_RECEIVED="$(echo $line | jq --raw-output '.id' | tr -s ' ' '_')"

  MQTT_PATH=$MQTT_TOPIC
  echo $line

  # Create file with touch /tmp/rtl_433.log if logging is needed
  [ -w /tmp/rtl_433.log ] && echo $line >> rtl_433.log
  if [ "$DEVICEID_RECEIVED" -eq "$DEVICEID" ]; then
    echo $line | /usr/bin/mosquitto_pub -h $MQTT_HOST -u $MQTT_USER -P $MQTT_PASS -i RTL_433 -r -l -t $MQTT_PATH
  fi
done