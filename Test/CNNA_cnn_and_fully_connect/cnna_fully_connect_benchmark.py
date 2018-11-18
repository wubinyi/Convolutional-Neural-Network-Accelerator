import numpy as np
import matplotlib.pyplot as plt

def cnna_calculated_time(cnna_parameter):
	picture_height = cnna_parameter[0]
	picture_width = cnna_parameter[1]
	filter_height = cnna_parameter[2]
	filter_width = cnna_parameter[3]
	output_channels = cnna_parameter[4]
	in_channels = cnna_parameter[5]
	stride = cnna_parameter[6]

	shift_time = ((picture_width - filter_width)/stride + 1) * ((picture_height - filter_height)/stride + 1)

	neuron_fetch_time = shift_time * filter_width * filter_height - 2


	filter_fetch_time = filter_height * filter_width * output_channels
	filter_fetch_time = filter_fetch_time * 2

	load_neuron_time_candidate0 = picture_height * picture_width
	load_neuron_time_candidate1 = picture_height * 7
	if picture_width < 7:
		load_neuron_time = load_neuron_time_candidate0 * 2
	else:
		load_neuron_time = load_neuron_time_candidate1 * 2


	multiply_counter = (neuron_fetch_time + 2) * in_channels * output_channels
	# adder_counter = ((filter_width * filter_height - 1) * in_channels + in_channels - 1) * shift_time * output_channels
	adder_counter = (filter_width * filter_height * in_channels - 1) * output_channels


	pre_fetch_time = filter_fetch_time + load_neuron_time
	computation_time = neuron_fetch_time + 16
	fixed_time = 6
	total_time = pre_fetch_time + computation_time + fixed_time

	return pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter

# print(cnna_calculated_time([4,4,4,4,8,10,1]))


def find_height_width(num):
	height_r = 0
	width_r = 0
	for width in range(1,7):
		height = (int)(num / width)
		temp = height * width
		if temp == num:
			height_r, width_r = height, width
	return height_r, width_r

# # =========== input size ===========
# [batch, in_height, in_width, in_channels] = [1, x, y, z]
# [filter_height, filter_width, in_channels, out_channels] = [x, y, z, 8]
# stride = 1
y_pre_fetch_time = []
y_computation_time = []
y_fixed_time = []
y_total_time = []
y_multiply_counter = []
y_adder_counter = []
for i in range(16, 16*36+1, 16):
	z = 16
	x, y = find_height_width((int)(i / 16))
	cnna_parameter = [x, y, x, y, 8, z, 1]
	pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter = cnna_calculated_time(cnna_parameter)
	y_pre_fetch_time.append(pre_fetch_time)
	y_computation_time.append(computation_time)
	y_fixed_time.append(fixed_time)
	y_total_time.append(total_time)
	y_multiply_counter.append(multiply_counter)
	y_adder_counter.append(adder_counter)

y_max = max(y_total_time)
x_label = list(range(16, 16*36+1, 16))

width = 10       # the width of the bars: can also be len(x) sequence

plt.figure(1)

plt.subplot(2, 1, 1)
plt.title('Benchmark VS Input Size \n ')
p0 = plt.bar(x_label, y_fixed_time, width)
p1 = plt.bar(x_label, y_pre_fetch_time, width, bottom=y_fixed_time)
p2 = plt.bar(x_label, y_computation_time, width,bottom=y_pre_fetch_time)
p3 = plt.plot(x_label, y_total_time, 'r--')
x_label_str = []
x_label_str.extend(str(e) for e in x_label)
plt.xticks(x_label, x_label_str[:])
plt.xlabel('Input Size')
plt.ylabel('Total Clocks')
plt.legend((p0[0], p1[0], p2[0], p3[0]), ('fixed clocks', 'prefetch clocks', 'computation clocks', 'total clocks'))

plt.subplot(2, 1, 2)
p4 = plt.bar(x_label, y_multiply_counter, width)
p5 = plt.bar(x_label, y_adder_counter, width, bottom=y_multiply_counter)
plt.xlabel('Input Size')
plt.ylabel('multiplications and additions')
plt.xticks(x_label, x_label_str[:])
# plt.title('clocks vs filter_width')
plt.legend((p4[0], p5[0]), ('multiplication', 'addition'))

plt.show()


# # =========== output_channels ===========
# # [batch, in_height, in_width, in_channels] = [1, 3, 3, 8]
# # [filter_height, filter_width, in_channels, out_channels] = [3, 3, 8, x]
y_pre_fetch_time = []
y_computation_time = []
y_fixed_time = []
y_total_time = []
y_multiply_counter = []
y_adder_counter = []
y_before_computation_time = []
for x in range(1,17):
	cnna_parameter = [3, 3, 3, 3, x, 8, 1]
	pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter = cnna_calculated_time(cnna_parameter)
	y_pre_fetch_time.append(pre_fetch_time)
	y_computation_time.append(computation_time)
	y_fixed_time.append(fixed_time)
	y_total_time.append(total_time)
	y_before_computation_time.append(pre_fetch_time+fixed_time)
	y_multiply_counter.append(multiply_counter)
	y_adder_counter.append(adder_counter)

y_max = max(y_total_time)
x_label = list(range(1,17))

width = 0.5       # the width of the bars: can also be len(x) sequence

plt.figure(2)
plt.subplot(2, 1, 1)
p0 = plt.bar(x_label, y_fixed_time, width)
p1 = plt.bar(x_label, y_pre_fetch_time, width, bottom=y_fixed_time)
p2 = plt.bar(x_label, y_computation_time, width,bottom=y_pre_fetch_time)
p3 = plt.plot(x_label, y_total_time, 'r--')
p4 = plt.plot(x_label, y_before_computation_time, 'b--')
plt.xlabel('number of output channels')
plt.ylabel('total clocks')
plt.title('Benchmark VS Output Channels')
# plt.yticks(np.arange(0, 9001, 1000))
plt.legend((p0[0], p1[0], p2[0], p3[0]), ('fixed clocks', 'prefetch clocks', 'computation clocks', 'total clocks'))

plt.subplot(2, 1, 2)
p4 = plt.bar(x_label, y_multiply_counter, width)
p5 = plt.bar(x_label, y_adder_counter, width, bottom=y_multiply_counter)
plt.xlabel('number of output channels')
plt.ylabel('multiplications and additions')
# plt.title('clocks vs filter_width')
plt.legend((p4[0], p5[0]), ('multiplication', 'addition'))

plt.show()


# =========== input channels ===========
# [batch, in_height, in_width, in_channels] = [1, 3, 3, x]
# [filter_height, filter_width, in_channels, out_channels] = [3, 3, x, 8]
# y_pre_fetch_time = []
# y_computation_time = []
# y_fixed_time = []
# y_total_time = []
# y_multiply_counter = []
# y_adder_counter = []
# y_before_computation_time = []
# for x in range(1,17):
# 	cnna_parameter = [3, 3, 3, 3, 8, x, 1]
# 	pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter = cnna_calculated_time(cnna_parameter)
# 	y_pre_fetch_time.append(pre_fetch_time)
# 	y_computation_time.append(computation_time)
# 	y_fixed_time.append(fixed_time)
# 	y_total_time.append(total_time)
# 	y_before_computation_time.append(pre_fetch_time+fixed_time)
# 	y_multiply_counter.append(multiply_counter)
# 	y_adder_counter.append(adder_counter)

# y_max = max(y_total_time)
# x_label = list(range(1,17))

# width = 0.5       # the width of the bars: can also be len(x) sequence

# plt.figure(2)
# plt.subplot(2, 1, 1)
# p0 = plt.bar(x_label, y_fixed_time, width)
# p1 = plt.bar(x_label, y_pre_fetch_time, width, bottom=y_fixed_time)
# p2 = plt.bar(x_label, y_computation_time, width,bottom=y_pre_fetch_time)
# p3 = plt.plot(x_label, y_total_time, 'r--')
# p4 = plt.plot(x_label, y_before_computation_time, 'b--')
# plt.xlabel('number of input channels')
# plt.ylabel('total clocks')
# plt.title('Benchmark VS Iutput Channels')
# # plt.yticks(np.arange(0, 9001, 1000))
# plt.legend((p0[0], p1[0], p2[0], p3[0]), ('fixed clocks', 'prefetch clocks', 'computation clocks', 'total clocks'))

# plt.subplot(2, 1, 2)
# p4 = plt.bar(x_label, y_multiply_counter, width)
# p5 = plt.bar(x_label, y_adder_counter, width, bottom=y_multiply_counter)
# plt.xlabel('number of input channels')
# plt.ylabel('multiplications and additions')
# # plt.title('clocks vs filter_width')
# plt.legend((p4[0], p5[0]), ('multiplication', 'addition'))

# plt.show()


# =========== peak perfomance ===========
pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter = cnna_calculated_time([6,6,6,6,16,16,1])
width = 0.5 
y1 = [fixed_time, 0]
y2 = [0, adder_counter]
y3 = [pre_fetch_time, 0]
y4 = [0, multiply_counter]
y5 = [computation_time, 0]
x_label = list(range(1,3))
p0 = plt.bar(x_label, y1, width)
p1 = plt.bar(x_label, y2, width, bottom=y1)
p2 = plt.bar(x_label, y3, width, bottom=y2)
p3 = plt.bar(x_label, y4, width, bottom=y3)
# p4 = plt.bar(x_label, y5, width, bottom=y4)
plt.xticks(x_label, ('computation clocks', 'multiplications and additions'))
# plt.legend((p0[0], p1[0], p2[0], p3[0], p4[0]),\
# 			 ('fixed clocks', 'additions', 'prefetch clocks', 'multiplications', 'computation clocks'))
print("total clocks: ", total_time)
print("multiply_counter: ", multiply_counter)
print("adder_counter: ", adder_counter)
plt.show()
