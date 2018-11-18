import os
os.environ['TF_CPP_MIN_LOG_LEVEL']='2'

import tensorflow as tf
import numpy as np

#np.set_printoptions(threshold=np.inf)
import pickle
from tensorflow.python.platform import gfile
from tensorflow.examples.tutorials.mnist import input_data

model_filename_before_quantization = "saved_model/cnn_sa_test.pb";
model_filename_after_quantization = "quantization_model/cnn_sa_test_quantizate.pb";
model_filename = model_filename_after_quantization;

# input  [batch, in_height, in_width, in_channels]
# filter [filter_height, filter_width, in_channels, out_channels]
filter_width = 3
filter_height = filter_width
feature_map_height = 10
feature_map_width = 10
input_channels = 16
output_channels = 16

# print one 'variable'/operation name, but now it is constant not variable
# with tf.Session() as sess:
#     with open(model_filename, 'rb') as f:
#         graph_def = tf.GraphDef()
#         graph_def.ParseFromString(f.read()) 
#         output = tf.import_graph_def(graph_def, return_elements=['W1:0'])
#         print(sess.run(output)) 

# print operation name and operation type, print all variable and other result
# with open(model_filename, 'rb') as f:
#     graph_def = tf.GraphDef()
#     graph_def.ParseFromString(f.read())
# output = tf.import_graph_def(graph_def)
# graph = tf.get_default_graph()
# for op in graph.get_operations():
# 	print(op.name, op.type)

# use quantized mode to do inference work and get accuracy
# mnist = input_data.read_data_sets('MNIST_data', one_hot=True, reshape=True)
# X = tf.placeholder(tf.float32, [None, 784])
# Y_ = tf.placeholder(tf.float32, [None, 10])
# dropout = tf.placeholder(tf.float32)
# with tf.Session() as sess:
#     with open(model_filename, 'rb') as f: 
#         graph_def = tf.GraphDef()
#         graph_def.ParseFromString(f.read()) 
#         X = tf.placeholder(tf.float32, [None, 784], name="X")
#         output = tf.import_graph_def(graph_def, input_map={'X:0': X, 'Y_:0': Y_,'dropout:0': dropout}, 
# 														return_elements=['accuracy:0']) 
#         print(sess.run(output, feed_dict={X: mnist.test.images,
#                                       Y_: mnist.test.labels,
#                                       dropout: 1.}))

# use quantized mode or unquantized mode to do inference work
# If you have change the name of each operation node or change the model, please run the code
# 		(line 34 - 40) firstly and update the list "node_name", then run the following code finally. 
# If you just change the parameter(height, width, channels), you can directly run the following code
node_name = [	'reshape_X_eightbit_reshape_X:0',
				'reshape_X_eightbit_min_X:0','reshape_X_eightbit_max_X:0',
				'reshape_X_eightbit_quantize_X:0','reshape_X_eightbit_quantized_reshape:0',
				'W1_quint8_const:0','W1_min:0','W1_max:0','first_conv_eightbit_quantized_conv:0',
				'first_conv_eightbit_requant_range:0','first_conv_eightbit_requantize:0',
				'B1_quint8_const:0','B1_min:0','B1_max:0','first_bias_eightbit_quantized_bias_add:0',
				'first_bias_eightbit_requant_range:0','first_bias_eightbit_requantize:0',
				'Y1_eightbit_quantized:0','Y1:0']
mnist = input_data.read_data_sets('MNIST_data', one_hot=True, reshape=True)
X = tf.placeholder(tf.float32, [None, feature_map_height*feature_map_width*input_channels], name="X")
with tf.Session() as sess:
    with open(model_filename, 'rb') as f: 
        graph_def = tf.GraphDef()
        graph_def.ParseFromString(f.read()) 
        output = tf.import_graph_def(graph_def, input_map={'X:0': X}, 
														return_elements=node_name) 
        # batch_X = np.array([[0.8,1.,1.,1.,1.,0.,0.,0.1,1.,0.05,0.,0.,0.95,0.,0.,0.,1.,0.,0.,0.,0.85,0.,0.,0.,0.]])
        batch_X = np.random.random_sample((1,feature_map_height*feature_map_width*input_channels))
        output_list = sess.run(output, feed_dict={X: batch_X})
print('X:0')
print(batch_X.shape)
print(batch_X.dtype)
np.savetxt('model_parameter/cnn_sa_test_V1/X:0', batch_X, fmt='%-14.4f')
for op in zip(output_list,node_name):
	print('')
	print(op[1])
	print(op[0].shape)
	data_type = op[0].dtype
	print(data_type)
	file_path = 'model_parameter/cnn_sa_test_V1/'+op[1]
	data = op[0].reshape((1,-1))
	np.savetxt(file_path, data, fmt='%-14.4f')