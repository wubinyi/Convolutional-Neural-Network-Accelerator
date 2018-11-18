# Enter Tensorflow's install direction, hier is ~/tensorflow
# use following command to quantizate the model
# input is the unquantized model
# output is the path to store the quantized model
# bazel-bin/tensorflow/tools/quantization/quantize_graph --input=/home/wubinyi/Machine_Learning_NN/Tensorflow/saved_model/cnn_sa_test.pb --output_node_name="Y1" --print_node --output=/home/wubinyi/Machine_Learning_NN/Tensorflow/quantization_model/cnn_sa_test_quantizate.pb --mode=eightbit


import os
os.environ['TF_CPP_MIN_LOG_LEVEL']='2'
import tensorflow as tf
import math
from tensorflow.examples.tutorials.mnist import input_data as mnist_data
from tensorflow.python.framework import graph_util

# input  [batch, in_height, in_width, in_channels]
# filter [filter_height, filter_width, in_channels, out_channels]
filter_width = 3
filter_height = filter_width
feature_map_height = 10
feature_map_width = 10
input_channels = 16
output_channels = 16

# filename_num = str(filter_height)+"_"+str(filter_width)+"_"+str(feature_map_height)+"_"+str(feature_map_width)+"_"+str(input_channels)+"_"+str(output_channels)+"_"
# filename = "saved_model/cnna_sa_"+filename_num+".pb"

X = tf.placeholder(tf.float32, [None, feature_map_height*feature_map_width*input_channels], name="X")
X = tf.reshape(X, shape=[-1, feature_map_height, feature_map_width, input_channels], name='reshape_X')

W1 = tf.Variable(tf.truncated_normal([filter_height, filter_width, input_channels, output_channels], stddev=0.1), name="W1")
B1 = tf.Variable(tf.random_normal([output_channels]), name="B1")


stride = 1  # output is 24x24
Y1l = tf.nn.conv2d(X, W1, strides=[1, stride, stride, 1], padding='VALID', name='first_conv')
Y1bias = tf.nn.bias_add(Y1l, B1, name='first_bias')
Y1 = tf.nn.relu(Y1bias, name="Y1")

init = tf.global_variables_initializer()

with tf.Session() as sess:
	sess.run(init)
	output_graph_def = graph_util.convert_variables_to_constants(sess, sess.graph_def, ['Y1'])
	with tf.gfile.GFile("saved_model/cnn_sa_test.pb", "wb") as f: 
	# with tf.gfile.GFile(filename, "wb") as f: 
		f.write(output_graph_def.SerializeToString())