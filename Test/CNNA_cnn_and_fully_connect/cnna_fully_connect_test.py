# 2018-02-17： used bitstream creat at 2018-02-14
#		only support input_height = input_width
#
# 2018-02-19： used bitstream creat at 2018-02-18 ---> lastest version
#		support input_height <= 32
#				input_width <= 6
#				but input_height * input_width <= 36
#
import socket
from datetime import *
import os
os.environ['TF_CPP_MIN_LOG_LEVEL']='2'
import tensorflow as tf
import numpy as np
import math
from tensorflow.examples.tutorials.mnist import input_data as mnist_data
from tensorflow.python.framework import graph_util

# fully connect layer: [1, N] * [N, M] = [1, M]
# N: number of outputs(neurons) in the previous layer
# M: number of outputs(neruons) in this layer
#
# X is input, W is neuron weight, Y is output
# The following has 8 input, 5 neuron(5 output), each neuron has 8 weights(corresponds to 8 inputs)
# |X1 X2 X3 X4 X5 X6 X7 X8| * |w01 w11 w21 w31 w41| = |Y1 Y2 Y3 Y4 Y5|
# 							  |w02 w12 w22 w32 w42|
# 							  |w03 w13 w23 w33 w43|
# 							  |w04 w14 w24 w34 w44|
# 							  |w05 w15 w25 w35 w45|
# 							  |w06 w16 w26 w36 w46|
# 							  |w07 w17 w27 w37 w47|
# 							  |w08 w18 w28 w38 w48| 
# 
# Each W(wx1, wx2, wx3, wx4, wx5, wx6, wx6, wx7, wx8) is a neuron's connection weight. 
#			For example: the second neuron has weights (w11, w12, w13, w14, w15, w16, w16, w17, w18)
#
# I suggest to divide each W into 16 equal parts whenever possible. --> accelerate fastest
# 	For example, if each W is 36, in order to divide into 16 equal parts, we need to add 16*3-36=12 0 at the end
# Why is 16 parts?
# Because CNNA has 16 channels for each filter, they computate at the same time, and finally sum over themself.
# So if we distributed each neuron into 16 "channels", we can accelerate fastest(16 times).
#
# Single chip support maximal 16*36*=576 inputs, 16 neurons

#======================================================================
# paramters
#======================================================================
# Fully connected layer does not have a concept of channels, height and width.
# The input data of fully-connected layer is a one dimension data.
# But we use CNNA(dedicatd for convolution) to accelerate it, so we need to represent the input data
# of a fully connect layer with channels, height and width.
# Note: input size of fully connected layer = height * weight * channels
input_height = 3
input_width = 4  
input_channels = 16

num_of_neurons = 16
num_of_input = input_height * input_width * input_channels

#======================================================================
# tensorflow part
#======================================================================
X = tf.placeholder(tf.float32, [1,num_of_input])
W = tf.placeholder(tf.float32, [num_of_input, num_of_neurons])
Y = tf.matmul(X, W)

x = np.random.random_integers(100, size=(1,input_height,input_width,input_channels))
xt = x.reshape(1,num_of_input)
x_f = xt.astype(float)
w = np.random.random_integers(50, size=(input_height,input_width,input_channels,num_of_neurons))
wt = w.reshape(num_of_input, num_of_neurons)
w_f = wt.astype(float)
print("--> X:")
print(x)
print("--> W:")
print(w)

sess = tf.Session()
Y_tf = sess.run(Y, feed_dict={X: x_f, W: w_f})
Y_tf_int = Y_tf.astype(int)

#======================================================================
# data transfered into udp bytes
#======================================================================
def weight_transfer(data):
	w_dimen = data.shape
	filter_height = w_dimen[0]
	filter_width = w_dimen[1]
	input_channel = w_dimen[2]
	output_channel = w_dimen[3]
	data_to_udp = []
	for i in range(0, output_channel):
		for j in range(0, filter_height):
			for k in range(0, filter_width):
				# print(i,j,k)
				data_to_udp.extend(np.zeros(16-input_channel, dtype=int))
				data_list = data[j, k, :, i].tolist()
				data_list.reverse()
				data_to_udp.extend(data_list)

	for j in range(0,output_channel*filter_height*filter_width):
		print(data_to_udp[j*16: j*16+16])

	return data_to_udp

def neuron_input_transfer(data):
	w_dimen = data.shape
	neuron_bacth = w_dimen[0]
	neuron_height = w_dimen[1]
	neuron_width = w_dimen[2]
	neuron_channel = w_dimen[3]
	data_to_udp = []
	for i in range(0, neuron_width):
		for j in range(0, neuron_height):  # height first when load neuron activation
			data_to_udp.extend(np.zeros(16-neuron_channel, dtype=int))
			data_list = data[0, j, i, :].tolist()
			data_list.reverse()
			data_to_udp.extend(data_list)	

	for j in range(0,neuron_height*neuron_width):
		print(data_to_udp[j*16: j*16+16])

	return data_to_udp	


print("\n--> neuron weights udp data format: ")
neuron_weight_udp = weight_transfer(w)
print("--> neuron input udp data  format: ")
neuron_input_udp = neuron_input_transfer(x)
# os._exit(0)

#======================================================================
# communication with CNNA
#======================================================================
# UDP connection
UDP_IP =  "192.168.0.1"
UDP_PORT_SELF = 1800
UDP_PORT_FPGA = 1800

UDP_MAGIC_SEND    = [0x72,0x2a,0xcc,0xe7]
UDP_MAGIC_RECV    = [0x2e,0x2a,0xcc,0xe7]
CNNA_START_UDP    = [0x5a,0x2a,0xcc,0xe7]

sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP

sock.bind(("192.168.0.2", UDP_PORT_SELF))

def bytes_to_int(bytes):
	result = 0
	for a in bytes:
		result = result * 256 + int(a)
	return result

def data_to_hex(data, len):
	hex_data = []
	for x in range(0,len):
		x_scale = (int)(x * 4)
		data_bytes = data[x_scale : x_scale+4]
		int_data = bytes_to_int(data[x_scale : x_scale+4])
		hex_data.append(int_data)
	return hex_data

# combine udp data
sram_data = [0x00,0x00,0x00,0x00,0x02,0x18,0x00,0x1a,0x02,0x02,0x00,0x4e,0x04,0x04,0x08,0x02,\
				0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x00,0x02]

sram_data[2] = input_height - 1
load_neuron_time = input_height * input_width
load_filter_time = input_height * input_width * num_of_neurons
sram_data[5] = load_neuron_time-1
sram_data[7] = load_filter_time-1
sram_data[8] = input_channels - 1
sram_data[9] = num_of_neurons - 1
cnna_computation_clocks = input_height * input_width  - 3
cnna_computation_clocks_high = (int)(cnna_computation_clocks / 255)
cnna_computation_clocks_low = cnna_computation_clocks % 255
sram_data[10] = cnna_computation_clocks_high
sram_data[11] = cnna_computation_clocks_low
sram_data[12] = input_height - 1
sram_data[13] = input_width - 1
sram_data[14] = input_height * input_width - 1
sram_data[15] = input_width - 1

print("\n first two words of sram_data:")
print(sram_data[0:16])
print(sram_data[16:])

sram_data.extend(neuron_weight_udp)
sram_data.extend(neuron_input_udp)


# send data to FPGA SRAM
print("\n-> send data to FPGA...")
bytes_send = 2 + input_height * input_width * num_of_neurons + input_height * input_width
if bytes_send > 256:
	print("\n----------------------------------------------")
	print("\n----->>>>  ERROR: SRAM not enough  <<<<-----")
	print("           Words need to send: ",bytes_send)
	print("\n----------------------------------------------")
	os._exit(1)
print("			send %d times!", bytes_send)
for x in range(0, bytes_send):
	base = x * 16
	data = []
	data.extend(UDP_MAGIC_SEND)
	word = sram_data[x*16: x*16+16]
	data.extend(word)
	address = [0,0,0,x]
	data.extend(address)
	# print(" number %d, length is %d" %(x, len(data)))

	byte_data = bytes(data)
	# print(byte_data)
	#int_data = int.from_bytes(byte_data[0])
	# print(hex(byte_data[0]))

	# string_data = ''.join(chr(element) for element in data)
	# print(string_data)

	sock.sendto(byte_data, (UDP_IP, UDP_PORT_FPGA))

	# delay
	a = 0
	for x in range(1,0xFFFF):
		for y in range(1,2):
			a = a+1;


# delay for udp_sram receiving data corretly
print("\n-> wait data transimission")
a = 0
for x in range(1,0xFFFFF):
  for y in range(1,2):
    a = a+1;


# send CNNA_START_UDP to udp_sram
print("\n-> wake up cnna")
data_wakeup = []
clock_counter = []
data_wakeup.extend(CNNA_START_UDP)
byte_data_wakeup = bytes(data_wakeup)
print(" byte_data_wakeup: ", byte_data_wakeup)
sock.sendto(byte_data_wakeup, (UDP_IP, UDP_PORT_FPGA))
begin = datetime.now()


#receive CNNA_FINISH_UDP from udp_sram
rec_data, addr = sock.recvfrom(2014)
end = datetime.now()
time_step = end - begin
time_step_second = time_step.total_seconds()
print("time_step_second: ", time_step_second)
print("\n-> after waiting for cnna finish signal")
print("first byte: ",hex(rec_data[0]))
print("clock bytes: ",rec_data[4:])
clock_counter.extend(rec_data[:])
print('clock_counter: ', clock_counter)
len_clock_counter = (int)((len(clock_counter)) / 4)
clock_counter_string = data_to_hex(clock_counter, len_clock_counter)
print(clock_counter_string)


# delay
print("\n-> cnna computing")
a = 0
# for x in range(1,0x3FFFFFF):
for x in range(1,0xFFFF):
  for y in range(1,2):
    a = a+1;



# read data from FPGA SRAM
print("-> read data from FPGA")
cnna_result_height = 1
cnna_result_width = 1
filter_output_channels = num_of_neurons
cnna_computate_result_transfer = np.zeros((1,cnna_result_height,cnna_result_width,filter_output_channels), dtype=int)
# result = []
bytes_receive = 1
print("			receive %d times!", bytes_receive)
cnna_computate_result = []

for x in range(0, cnna_result_width):
	for y in range(0, cnna_result_height):
		result = []
		# print("\n-> sending UDP_MAGIC_RECV...")
		data = []
		data.extend(UDP_MAGIC_RECV)
		byte_data_rec = bytes(data)
		# print(" byte_data_rec(UDP_MAGIC_RECV): ", byte_data_rec)
		sock.sendto(byte_data_rec, (UDP_IP, UDP_PORT_FPGA))

		# print("\n-> receiving data from udp_sram...")
		rec_data, addr = sock.recvfrom(2014)
		# print("first byte: ",hex(rec_data[0]))
		print("list length: ", len(rec_data))
		result.extend(rec_data[4:])

		print(" result: ", result)

		len_rec_data = (int)((len(result)) / 4)
		hex_string = data_to_hex(result, len_rec_data)
		cnna_computate_result.extend(hex_string[:filter_output_channels])
		print(hex_string)
		print(type(result))
		cnna_computate_result_transfer[0, y, x, :] = hex_string[:filter_output_channels]




# type(cnna_computate_result)
# cnna_computate_result_array = np.asarray(cnna_computate_result).reshape(1,cnna_result_height,cnna_result_width,filter_output_channels)
# print("cnna_computate_result_array")
# print(cnna_computate_result_array)
print("Y_tf_int")
print(Y_tf_int)
print("cnna_computate_result_transfer")
print(cnna_computate_result_transfer)

print("\n=======================================================")
if np.array_equal(Y_tf_int, cnna_computate_result_transfer.reshape(1, num_of_neurons)):
	print("\n           cnna successful")	
else:
	print("\n             cnna fail")
print("\n         cnna computation clocks: ", clock_counter_string)
print("\n         cnna prefetch clocks   : ", bytes_send)

print("\n output shape of tensorflow: ", Y_tf_int.shape)

print("\n=======================================================")


#======================================================================
# find optimum width and heigt of neuron input
#======================================================================
# def find_width_height(seperate_part_size):
# 	width_result = 0
# 	height_result = 0
# 	error_result = seperate_part_size
# 	for width in range(1, 7):
# 		height = (int)((seperate_part_size+width-1) / width)
# 		resize = width * height
# 		error = resize - seperate_part_size
# 		if error <= error_result:
# 			error_result = error
# 			width_result = width
# 			height_result = height
# 	return height_result, width_result

# feature_map_height, feature_map_width = find_width_height(seperate_parts)
# print("optimum height and width: ", feature_map_height, feature_map_width)

#======================================================================
# data transfered into udp bytes
#======================================================================
# def weight_transfer(weights, num_of_neurons, expand_size, seperate_parts):
# 	data_to_udp = []
# 	for i in range(0, num_of_neurons):
# 		neuron_weight = weights[:,i]
# 		neuron_weight_expand = np.r_[neuron_weight, np.zeros(expand_size,)]
# 		for j in range(0, seperate_parts):
# 			j_scale = j * 16
# 			weight_list = neuron_weight_expand[j_scale: j_scale+16].tolist()
# 			print(weight_list)
# 			data_to_udp.extend(weight_list)
# 		print("\n")

# 	return data_to_udp

# def neuron_input_transfer(neuron_inputs, expand_size, seperate_parts, feature_map_height, feature_map_width):
# 	data_to_udp = []
# 	neuron_inputs_expand = np.r_[neuron_inputs, np.zeros(expand_size,)]
# 	neuron_inputs_expand_t = neuron_inputs_expand.reshpae((feature_map_height, feature_map_width, 16))
# 	for i in range(0, feature_map_width):
# 		for j in range(0, feature_map_height):  # height first when load neuron activation
# 			data_to_udp.extend(np.zeros(16-neuron_channel, dtype=int))
# 			data_list = data[0, j, i, :].tolist()
# 			data_list.reverse()
# 			data_to_udp.extend(data_list)

# 	# for j in range(0, seperate_parts):
# 	# 	j_scale = j * 16
# 	# 	neuron_input_list = neuron_inputs_expand[j_scale: j_scale+16].tolist()
# 	# 	print(neuron_input_list)
# 	# 	data_to_udp.extend(neuron_input_list)

# 	return data_to_udp

# print("\n--> neuron weights udp data format: ")
# neuron_weight_udp = weight_transfer(w, num_of_neurons, expand_size, seperate_parts)
# print("--> neuron input udp data  format: ")
# neuron_input_udp = neuron_input_transfer(x[0,:], expand_size, seperate_parts, feature_map_height, feature_map_width)
# os._exit(0)