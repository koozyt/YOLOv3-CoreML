#!/bin/sh

if [ $# -ne 4 ]; then
	echo "Usage: "$0" YOLOv3.cfg YOLOv3.weights YOLOv3.h5 YOLOv3.mlmodel"
	exit 1
fi
# python convert.py yolov3.cfg yolov3.weights model_data/yolo.h5

python convert.py $1 $2 $3
python coreml.py $3 $4
