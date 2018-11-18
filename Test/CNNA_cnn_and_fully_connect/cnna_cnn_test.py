# 2018-02-17： used bitstream creat at 2018-02-14
#		stride: only support 1
#		filter height/width:
#				1: do not support
#				2:	only success under feature width smaller than 8
#					reason: mem_read_en take control over mem_write_en
#				3-6: success
#				> 6: do not support; For larger model need to split the model
#		input channel: limited to 16; For larger model need to split the model
# 		output channel: limited to 16; For larger model need to split the model
# 		feature map height: limited to 32; For larger feature map height need to split the feature map
#		feature map width: no limitation
#
# 2018-02-19： used bitstream creat at 2018-02-18 ---> lastest version
#		stride: only support 1
#		filter height/width:
#				1: only success under feature width smaller than 8
#				2-6: success
#				> 6: do not support; For larger model need to split the model
#		input channel: limited to 16; For larger model need to split the model
# 		output channel: limited to 16; For larger model need to split the model
# 		feature map height: limited to 32; For larger feature map height need to split the feature map
#		feature map width: no limitation
#		
# 		memory limitation: 
#			2 + filter_height * filter_width * filter_output_channels + feature_map_height * feature_map_width <  "sram depth"(256)
import socket
from datetime import *
import os
os.environ['TF_CPP_MIN_LOG_LEVEL']='2'
import tensorflow as tf
import numpy as np
import math
from tensorflow.examples.tutorials.mnist import input_data as mnist_data
from tensorflow.python.framework import graph_util

#=================================================================
# 						parameter
#=================================================================
cnna_input_channels = 16
filter_width_height = 6

feature_map_height = 12
feature_map_width = 12
feature_map_channals = cnna_input_channels

filter_height = filter_width_height
filter_width = filter_width_height
filter_input_channels = cnna_input_channels
filter_output_channels = 3

#=================================================================
# 						tensorflow 
#=================================================================
X = tf.placeholder(tf.float32, [1,feature_map_height,feature_map_width,feature_map_channals])
W = tf.placeholder(tf.float32, [filter_height,filter_width,filter_input_channels,filter_output_channels])
Y = tf.nn.conv2d(X, W, strides = [1,1,1,1], padding='VALID')

sess = tf.Session()
# x = np.arange(0,75,1)
# xt = x.reshape(1,5,5,3)
# np.random.randint()
xt = np.random.random_integers(200, size=(1,feature_map_height,feature_map_width,feature_map_channals))
xt_f = xt.astype(float)
# w = np.arange(0,241,3)
# wt = w.reshape(3,3,3,3)
wt = np.random.random_integers(100, size=(filter_height,filter_width,filter_input_channels,filter_output_channels))
wt_f = wt.astype(float)
Y_return = sess.run(Y, feed_dict={X: xt_f, W: wt_f})
Y_return_int = Y_return.astype(int)
print(Y_return_int)
# print(Y_return[0,:,:,0]) #first channel


#=================================================================
# 		  multi-dimension data mapping into SRAM/UDP format
#=================================================================
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

def neruon_transfer(data):
	w_dimen = data.shape
	neuron_bacth = w_dimen[0]
	neuron_height = w_dimen[1]
	neuron_width = w_dimen[2]
	neuron_channel = w_dimen[3]
	data_to_udp = []
	for i in range(0, neuron_width):
		for j in range(0, neuron_height):  # "height" first when load neuron activation
			data_to_udp.extend(np.zeros(16-neuron_channel, dtype=int))
			data_list = data[0, j, i, :].tolist()
			data_list.reverse()
			data_to_udp.extend(data_list)	

	for j in range(0,neuron_height*neuron_width):
		print(data_to_udp[j*16: j*16+16])

	return data_to_udp	

print("weight sram/udp format")
filter_weight_udp = weight_transfer(wt)
print("feature map sram/udp format")
neuron_activation_udp = neruon_transfer(xt)


sram_data = [0x00,0x00,0x00,0x00,0x00,0x18,0x00,0x1a,0x02,0x02,0x00,0x4e,0x04,0x04,0x08,0x02,\
				0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x00,0x02]

if feature_map_width > 7:
	load_neuron_time = feature_map_height*7
else:
	load_neuron_time = feature_map_height*feature_map_width
# load_neuron_time = (feature_map_width > 7) ? feature_map_height*7 : feature_map_height*feature_map_width
load_filter_time = filter_height * filter_width * filter_output_channels
sram_data[5] = load_neuron_time-1
sram_data[7] = load_filter_time-1
sram_data[8] = filter_input_channels - 1
sram_data[9] = filter_output_channels - 1
cnna_computation_clocks = (feature_map_height - filter_height + 1 ) * ( feature_map_width - filter_width + 1 ) * \
							filter_width * filter_height  - 3
cnna_computation_clocks_high = (int)(cnna_computation_clocks / 255)
cnna_computation_clocks_low = cnna_computation_clocks % 255
sram_data[10] = cnna_computation_clocks_high
sram_data[11] = cnna_computation_clocks_low
sram_data[12] = feature_map_height - 1
sram_data[13] = feature_map_width - 1
sram_data[14] = filter_height * filter_width - 1
sram_data[15] = filter_width - 1

print("\n first two words of sram_data-configuration information:")
print(sram_data[0:16])
print(sram_data[16:])

sram_data.extend(filter_weight_udp)
sram_data.extend(neuron_activation_udp)


#=================================================================
# 		  			    UDP communication
#=================================================================
def bytes_to_int(bytes):
	result = 0
	for a in bytes:
		result = result * 256 + int(a)
	return result

def data_to_hex(data, len):
	hex_tri = []
	for x in range(0,len):
		x_scale = (int)(x * 4)
		data_bytes = data[x_scale : x_scale+4]
		int_data = bytes_to_int(data[x_scale : x_scale+4])
		# int_data = int.from_bytes(data_bytes, "big")
		# hex_tri.append(hex(int_data))
		hex_tri.append(int_data)
	return hex_tri


UDP_IP =  "192.168.0.1"
UDP_PORT_SELF = 1800
UDP_PORT_FPGA = 1800

UDP_MAGIC_SEND    = [0x72,0x2a,0xcc,0xe7]
UDP_MAGIC_RECV    = [0x2e,0x2a,0xcc,0xe7]
CNNA_START_UDP    = [0x5a,0x2a,0xcc,0xe7]

sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
sock.bind(("192.168.0.2", UDP_PORT_SELF))


# send data to FPGA SRAM
print("\n-> send data to FPGA...")
# words UDP need to send, can not over the sram size: 256
bytes_send = 2 + filter_height * filter_width * filter_output_channels + feature_map_height * feature_map_width
if bytes_send > 256:
	print("\n----------------------------------------------")
	print("\n----->>>>  ERROR: SRAM not enough  <<<<-----")
	print("           Words need to send: ",bytes_send)
	print("\n----------------------------------------------")
	os._exit(1)
print("			send %d times!" %bytes_send)
for x in range(0, bytes_send):
	base = x * 16
	data = []
	data.extend(UDP_MAGIC_SEND)
	word = sram_data[x*16: x*16+16]
	data.extend(word)
	address = [0,0,0,x]
	data.extend(address)

	byte_data = bytes(data)
	# print(byte_data)
	#int_data = int.from_bytes(byte_data[0])
	# print(hex(byte_data[0]))

	sock.sendto(byte_data, (UDP_IP, UDP_PORT_FPGA))

	# delay
	a = 0
	for x in range(1,0xFFFF):
		for y in range(1,2):
			a = a+1;

# delay for udp_sram receiving data corretly
# it is not necessary
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
# it is not necessary
print("\n-> cnna computing")
a = 0
# for x in range(1,0x3FFFFFF):
for x in range(1,0xFFFF):
	for y in range(1,2):
		a = a+1;

# read data from FPGA SRAM
print("-> read data from FPGA")
cnna_result_height = feature_map_height - filter_height + 1
cnna_result_width = feature_map_width - filter_width + 1
cnna_computate_result_transfer = np.zeros((1,cnna_result_height,cnna_result_width,filter_output_channels), dtype=int)
bytes_receive = (feature_map_height - filter_height + 1) * (feature_map_width - filter_width + 1)
print("			receive %d times!" %bytes_receive)
# cnna_computate_result = []

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
		# cnna_computate_result.extend(hex_string[:filter_output_channels])
		print(hex_string)
		print(type(result))
		cnna_computate_result_transfer[0, y, x, :] = hex_string[:filter_output_channels]


#=================================================================
# 		  			result compare and print
#=================================================================
# type(cnna_computate_result)
# cnna_computate_result_array = np.asarray(cnna_computate_result).reshape(1,cnna_result_height,cnna_result_width,filter_output_channels)
# print("cnna_computate_result_array")
# print(cnna_computate_result_array)
print("Y_return_int")
print(Y_return_int)
print("cnna_computate_result_transfer")
print(cnna_computate_result_transfer)

print("\n=======================================================")
if np.array_equal(Y_return_int, cnna_computate_result_transfer):
	print("\n           cnna successful")	
else:
	print("\n             cnna fail")
print("\n         cnna computation clocks: ", clock_counter_string)

print("\n output shape of tensorflow: ", Y_return_int.shape)

print("\n=======================================================")
