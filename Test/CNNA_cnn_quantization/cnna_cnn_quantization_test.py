# Please ensure this file is in the same folder with "model_parameter".
# Because I have already fixed path variable 'pathname'. If you change their folder relationship,
#		please modify this variable.
# You can not change parameter as you like, because I have only save some quantization model.
# The folders under folder "model_parameter" are the saved models/results from tensorflow
# These floders are named following: cnna_sa_x_x_x_x_x_x
#	x_x_x_x_x_x means filterHeight_filterWidth_featureHeight_featureWidth_inputChannels_outputChannels
#
# The models I saved are showed below：
# 	filterHeight_filterWidth_featureHeight_featureWidth_inputChannels_outputChannels
#		  3     |     3     |      10     |      10    |       6     |       6
#		  4     |     4     |      10     |      10    |       6     |       6
#		  5     |     5     |      10     |      10    |       6     |       6

#		  3     |     3     |      06     |      10    |       6     |       6
#		  3     |     3     |      08     |      10    |       6     |       6        
#		  3     |     3     |      12     |      10    |       6     |       6

#		  3     |     3     |      10     |      06    |       6     |       6
#		  3     |     3     |      10     |      08    |       6     |       6
#		  3     |     3     |      10     |      12    |       6     |       6

#		  3     |     3     |      10     |      10    |       7     |       6
#		  3     |     3     |      10     |      10    |       8     |       6
#		  3     |     3     |      10     |      10    |       9     |       6

#		  3     |     3     |      10     |      10    |       6     |       7
#		  3     |     3     |      10     |      10    |       6     |       8
#		  3     |     3     |      10     |      10    |       6     |       9

#		  3     |     3     |      10     |      10    |      16     |       16
#

import os
import numpy as np
import socket
from datetime import *


#=================================================================
# 						parameter
#=================================================================
# input  [batch, in_height, in_width, in_channels]
# filter [filter_height, filter_width, in_channels, out_channels]
filter_width = 3
filter_height = filter_width
feature_map_height = 10
feature_map_width = 10
input_channels = 16
output_channels = 16

conv_height = feature_map_height - filter_height + 1
conv_width = feature_map_width - filter_width + 1

foldername = str(filter_height)+"_"+str(filter_width)+"_"+str(feature_map_height)+ \
				"_"+str(feature_map_width)+"_"+str(input_channels)+"_"+str(output_channels)
pathname = "model_parameter/cnna_sa_"+foldername

#=================================================================
# 				load feature map and filter
#=================================================================
feature_map_file = pathname+"/reshape_X_eightbit_quantize_X_0"
feature_map = np.loadtxt(feature_map_file)
feature_map = feature_map.astype(int)
feature_map = feature_map.reshape(1, feature_map_height, feature_map_width, input_channels)
# print(feature_map.shape)

filter_file = pathname+"/W1_quint8_const_0"
filter_weight = np.loadtxt(filter_file)
filter_weight = filter_weight.astype(int)
filter_weight = filter_weight.reshape(filter_height, filter_width, input_channels, output_channels)
# print(type(filter_weight[0,0,0,0]))

tf_quan_conv_file = pathname+"/first_conv_eightbit_quantized_conv_0"
tf_quan_conv = np.loadtxt(tf_quan_conv_file)
tf_quan_conv = tf_quan_conv.astype(int)
tf_quan_conv = tf_quan_conv.reshape(1, conv_height, conv_width, output_channels)
# print(tf_quan_conv.shape)

weight_max_file = pathname+"/W1_max_0"
weight_max = np.loadtxt(weight_max_file)
# print(weight_max)

weight_min_file = pathname+"/W1_min_0"
weight_min = np.loadtxt(weight_min_file)
# print(weight_min)

weight_zero = (int)((256 / (weight_max - weight_min)) * (0 - weight_min))
print("weight_zero: ", weight_zero)
print("\n")


#=================================================================
# 	    multi-dimension data mapping into SRAM/UDP format
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
		for j in range(0, neuron_height):  # height first when load neuron activation
			data_to_udp.extend(np.zeros(16-neuron_channel, dtype=int))
			data_list = data[0, j, i, :].tolist()
			data_list.reverse()
			data_to_udp.extend(data_list)	

	for j in range(0,neuron_height*neuron_width):
		print(data_to_udp[j*16: j*16+16])

	return data_to_udp	


print("filter weight udp data:")
filter_weight_udp = weight_transfer(filter_weight)
print("feature map udp data:")
feature_map_udp = neruon_transfer(feature_map)

#=================================================================
# 		  configuration information udp data generation
#=================================================================
# // 			8'h00: data_bus_i <= 128'h0000_0088_0018_001a_0202_004e_0404_0802;
# // 			8'h01: data_bus_i <= 128'hffff_ffff_ffff_0000_1111_1111_1111_8002;
sram_data = [0x00,0x00,0x00,0x00,0x01,0x18,0x00,0x1a,0x02,0x02,0x00,0x4e,0x04,0x04,0x08,0x02,\
				0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x00,0x02]

sram_data[3] = weight_zero
if feature_map_width > 7:
	load_neuron_time = feature_map_height*7
else:
	load_neuron_time = feature_map_height*feature_map_width
# load_neuron_time = (feature_map_width > 7) ? feature_map_height*7 : feature_map_height*feature_map_width
load_filter_time = filter_height * filter_width * output_channels
sram_data[5] = load_neuron_time-1
sram_data[7] = load_filter_time-1
sram_data[8] = input_channels - 1
sram_data[9] = output_channels - 1
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

print("\n first two words of sram_data:")
print(sram_data[0:16])
print(sram_data[16:])

sram_data.extend(filter_weight_udp)
sram_data.extend(feature_map_udp)


#=================================================================
# 		  				UDP communication
#=================================================================
def bytes_to_int(bytes):
	result = 0.0
	result_int = 0
	for a in bytes:
		result = result * 256.0 + float(a)
	result_int = (int)(result)
	return result_int

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
bytes_send = 2 + filter_height * filter_width * output_channels + feature_map_height * feature_map_width
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

# delay for udp_sram receiving data correctly
# it is not necessary but ensure data correctly
# print("\n-> wait data transimission")
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
# it is not necessary but ensure data correctly
# print("\n-> cnna computing")
a = 0
for x in range(1,0xFFFF):
	for y in range(1,2):
		a = a+1;


# read data from FPGA SRAM
print("-> read data from FPGA")
cnna_computate_result = np.zeros((1,conv_height,conv_width,output_channels), dtype=np.int64)
bytes_receive = conv_height * conv_width
print("			receive %d times!", bytes_receive)
for x in range(0, conv_width):
	for y in range(0, conv_height):
		
		data = []
		data.extend(UDP_MAGIC_RECV)
		byte_data_rec = bytes(data)
		sock.sendto(byte_data_rec, (UDP_IP, UDP_PORT_FPGA))

		result = []
		rec_data, addr = sock.recvfrom(2014)
		print("list length: ", len(rec_data))
		result.extend(rec_data[4:])
		print("receive data: ", result)

		# con = (int)((len(result)) / 4)
		# print("convert data length: ", len_rec_data)
		hex_string = data_to_hex(result, 16)
		print(hex_string)
		cnna_computate_result[0, y, x, :] = hex_string[:output_channels]

#=================================================================
# 		  			result compare and print
#=================================================================
# the decaleration of cnna_computate_result is int64, avoiding overflow error
# because the random data input is quite large(actual input data can not be so large), 
# sometime data after data_to_hex() function will be 0xFXXXX_XXXX, then python will 
# automatically use int64 to store it, so I use int64 numpy.narray to store it first
# Then transfer it back into int in order to compare with tensorflow's output(int32)
cnna_computate_result = cnna_computate_result.astype(int)

print("tf_quan_conv")
print(tf_quan_conv)
print("cnna_computate_result_transfer")
print(cnna_computate_result)

print("\n=======================================================")
if np.array_equal(tf_quan_conv, cnna_computate_result):
	print("\n           cnna successful")	
else:
	print("\n             cnna fail")
print("\n         cnna computation clocks: ", clock_counter_string)

print("\n output shape of tensorflow: ", tf_quan_conv.shape)

print("\n=======================================================")