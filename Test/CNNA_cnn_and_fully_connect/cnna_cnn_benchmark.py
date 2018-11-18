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
	adder_counter = ((filter_width * filter_height - 1) * in_channels + in_channels - 1) * shift_time * output_channels


	pre_fetch_time = filter_fetch_time + load_neuron_time
	computation_time = neuron_fetch_time + 16
	fixed_time = 6
	total_time = pre_fetch_time + computation_time + fixed_time

	return pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter

# # =========== filter_width ===========
# # [batch, in_height, in_width, in_channels] = [1, 28, 28, 5]
# # [filter_height, filter_width, in_channels, out_channels] = [x, x, 5, 10]
# # stride = 1
# y_pre_fetch_time = []
# y_computation_time = []
# y_fixed_time = []
# y_total_time = []
# y_multiply_counter = []
# y_adder_counter = []
# for x in range(2,7):
# 	cnna_parameter = [28, 28, x, x, 10, 5, 1]
# 	pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter = cnna_calculated_time(cnna_parameter)
# 	y_pre_fetch_time.append(pre_fetch_time)
# 	y_computation_time.append(computation_time)
# 	y_fixed_time.append(fixed_time)
# 	y_total_time.append(total_time)
# 	y_multiply_counter.append(multiply_counter)
# 	y_adder_counter.append(adder_counter)

# y_max = max(y_total_time)
# x_label = list(range(2,7))

# width = 0.5       # the width of the bars: can also be len(x) sequence

# plt.figure(1)

# plt.subplot(2, 1, 1)
# plt.title('Benchmark VS Filter Width \n ')
# p0 = plt.bar(x_label, y_fixed_time, width)
# p1 = plt.bar(x_label, y_pre_fetch_time, width, bottom=y_fixed_time)
# p2 = plt.bar(x_label, y_computation_time, width,bottom=y_pre_fetch_time)
# p3 = plt.plot(x_label, y_total_time, 'r--')
# plt.xlabel('filter width')
# plt.ylabel('total clocks')
# plt.legend((p0[0], p1[0], p2[0], p3[0]), ('fixed clocks', 'prefetch clocks', 'computation clocks', 'total clocks'))

# plt.subplot(2, 1, 2)
# p4 = plt.bar(x_label, y_multiply_counter, width)
# p5 = plt.bar(x_label, y_adder_counter, width, bottom=y_multiply_counter)
# plt.xlabel('filter width')
# plt.ylabel('multiplications and additions')
# # plt.title('clocks vs filter_width')
# plt.legend((p4[0], p5[0]), ('multiplication', 'addition'))

# plt.show()

# # =========== feature map height ===========
# # [batch, in_height, in_width, in_channels] = [1, x, 28, 5]
# # [filter_height, filter_width, in_channels, out_channels] = [3, 3, 5, 10]
# y_pre_fetch_time = []
# y_computation_time = []
# y_fixed_time = []
# y_total_time = []
# y_multiply_counter = []
# y_adder_counter = []
# for x in range(5,33):
# 	cnna_parameter = [x, 28, 3, 3, 10, 5, 1]
# 	pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter = cnna_calculated_time(cnna_parameter)
# 	y_pre_fetch_time.append(pre_fetch_time)
# 	y_computation_time.append(computation_time)
# 	y_fixed_time.append(fixed_time)
# 	y_total_time.append(total_time)
# 	y_multiply_counter.append(multiply_counter)
# 	y_adder_counter.append(adder_counter)

# y_max = max(y_total_time)
# x_label = list(range(5,33))

# width = 0.5       # the width of the bars: can also be len(x) sequence

# plt.figure(3)
# plt.subplot(2, 1, 1)
# p0 = plt.bar(x_label, y_fixed_time, width)
# p1 = plt.bar(x_label, y_pre_fetch_time, width, bottom=y_fixed_time)
# p2 = plt.bar(x_label, y_computation_time, width,bottom=y_pre_fetch_time)
# p3 = plt.plot(x_label, y_total_time, 'r--')
# plt.xlabel('feature map height')
# plt.ylabel('total clocks')
# plt.title('Benchmark VS Feature Map Height')
# plt.legend((p0[0], p1[0], p2[0], p3[0]), ('fixed clocks', 'prefetch clocks', 'computation clocks', 'total clocks'))

# plt.subplot(2, 1, 2)
# p4 = plt.bar(x_label, y_multiply_counter, width)
# p5 = plt.bar(x_label, y_adder_counter, width, bottom=y_multiply_counter)
# plt.xlabel('feature map height')
# plt.ylabel('multiplications and additions')
# # plt.title('clocks vs filter_width')
# plt.legend((p4[0], p5[0]), ('multiplication', 'addition'))

# plt.show()


# # =========== feature map width ===========
# # [batch, in_height, in_width, in_channels] = [1, 28, 28, 5]
# # [filter_height, filter_width, in_channels, out_channels] = [x, x, 5, 10]
# y_pre_fetch_time = []
# y_computation_time = []
# y_fixed_time = []
# y_total_time = []
# y_multiply_counter = []
# y_adder_counter = []
# for x in range(5,33):
# 	cnna_parameter = [x, 28, 3, 3, 10, 5, 1]
# 	pre_fetch_time, computation_time, fixed_time, total_time, multiply_counter, adder_counter = cnna_calculated_time(cnna_parameter)
# 	y_pre_fetch_time.append(pre_fetch_time)
# 	y_computation_time.append(computation_time)
# 	y_fixed_time.append(fixed_time)
# 	y_total_time.append(total_time)
# 	y_multiply_counter.append(multiply_counter)
# 	y_adder_counter.append(adder_counter)

# y_max = max(y_total_time)
# x_label = list(range(5,33))

# width = 0.5       # the width of the bars: can also be len(x) sequence

# plt.figure(4)
# plt.subplot(2, 1, 1)
# p0 = plt.bar(x_label, y_fixed_time, width)
# p1 = plt.bar(x_label, y_pre_fetch_time, width, bottom=y_fixed_time)
# p2 = plt.bar(x_label, y_computation_time, width,bottom=y_pre_fetch_time)
# p3 = plt.plot(x_label, y_total_time, 'r--')
# plt.xlabel('feature map width')
# plt.ylabel('total clocks')
# plt.title('Benchmark VS Feature Map Width')
# plt.legend((p0[0], p1[0], p2[0], p3[0]), ('fixed clocks', 'prefetch clocks', 'computation clocks', 'total clocks'))

# plt.subplot(2, 1, 2)
# p4 = plt.bar(x_label, y_multiply_counter, width)
# p5 = plt.bar(x_label, y_adder_counter, width, bottom=y_multiply_counter)
# plt.xlabel('feature map width')
# plt.ylabel('multiplications and additions')
# # plt.title('clocks vs filter_width')
# plt.legend((p4[0], p5[0]), ('multiplication', 'addition'))

# plt.show()


# # =========== output_channels ===========
# # [batch, in_height, in_width, in_channels] = [1, 28, 28, 5]
# # [filter_height, filter_width, in_channels, out_channels] = [3, 3, 5, x]
# y_pre_fetch_time = []
# y_computation_time = []
# y_fixed_time = []
# y_total_time = []
# y_multiply_counter = []
# y_adder_counter = []
# y_before_computation_time = []
# for x in range(1,17):
# 	cnna_parameter = [28, 28, 3, 3, x, 5, 1]
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
# plt.xlabel('number of output channels')
# plt.ylabel('total clocks')
# plt.title('Benchmark VS Output Channels')
# # plt.yticks(np.arange(0, 9001, 1000))
# plt.legend((p0[0], p1[0], p2[0], p3[0]), ('fixed clocks', 'prefetch clocks', 'computation clocks', 'total clocks'))

# plt.subplot(2, 1, 2)
# p4 = plt.bar(x_label, y_multiply_counter, width)
# p5 = plt.bar(x_label, y_adder_counter, width, bottom=y_multiply_counter)
# plt.xlabel('number of output channels')
# plt.ylabel('multiplications and additions')
# # plt.title('clocks vs filter_width')
# plt.legend((p4[0], p5[0]), ('multiplication', 'addition'))

# plt.show()


# =========== input channels ===========
# [batch, in_height, in_width, in_channels] = [1, 28, 28, x]
# [filter_height, filter_width, in_channels, out_channels] = [3, 3, x, 10]
y_pre_fetch_time = []
y_computation_time = []
y_fixed_time = []
y_total_time = []
y_multiply_counter = []
y_adder_counter = []
y_before_computation_time = []
for x in range(1,17):
	cnna_parameter = [28, 28, 3, 3, 10, x, 1]
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
plt.xlabel('number of input channels')
plt.ylabel('total clocks')
plt.title('Benchmark VS Iutput Channels')
# plt.yticks(np.arange(0, 9001, 1000))
plt.legend((p0[0], p1[0], p2[0], p3[0]), ('fixed clocks', 'prefetch clocks', 'computation clocks', 'total clocks'))

plt.subplot(2, 1, 2)
p4 = plt.bar(x_label, y_multiply_counter, width)
p5 = plt.bar(x_label, y_adder_counter, width, bottom=y_multiply_counter)
plt.xlabel('number of input channels')
plt.ylabel('multiplications and additions')
# plt.title('clocks vs filter_width')
plt.legend((p4[0], p5[0]), ('multiplication', 'addition'))

plt.show()





# =========== filter_width ===========
# [batch, in_height, in_width, in_channels] = [1, 28, 28, 5]
# [filter_height, filter_width, in_channels, out_channels] = [x, x, 5, 10]
# y_cnna_time = []
# for x in range(2,7):
# 	cnna_parameter = [28, 28, x, x, 10]
# 	y_cnna_time.append(cnna_calculated_time(cnna_parameter))
# x_filter_width = list(range(2,7))

# plt.figure(1)
# plt.plot(x_filter_width, y_cnna_time, 'ro')
# plt.xlabel('filter width')
# plt.ylabel('total clocks')
# plt.show()


# =========== output_channels ===========
# [batch, in_height, in_width, in_channels] = [1, 28, 28, 5]
# [filter_height, filter_width, in_channels, out_channels] = [3, 3, 5, x]
# y_cnna_time = []
# for x in range(1,17):
# 	cnna_parameter = [28, 28, 3, 3, x]
# 	y_cnna_time.append(cnna_calculated_time(cnna_parameter))
# x_output_channels = list(range(1,17))

# plt.figure(2)
# plt.plot(x_output_channels, y_cnna_time, 'ro')
# plt.xlabel('number of output channels')
# plt.ylabel('total clocks')
# plt.show()

# =========== neuron height ===========
# [batch, in_height, in_width, in_channels] = [1, x, 28, 5]
# [filter_height, filter_width, in_channels, out_channels] = [3, 3, 5, 10]
# y_cnna_time = []
# for x in range(5,33):
# 	cnna_parameter = [x, 28, 3, 3, 10]
# 	y_cnna_time.append(cnna_calculated_time(cnna_parameter))
# x_neuron_height = list(range(5,33))

# plt.figure(3)
# plt.plot(x_neuron_height, y_cnna_time, 'ro')
# plt.xlabel('neuron activation height')
# plt.ylabel('total clocks')
# plt.show()

# =========== neuron width ===========
# [batch, in_height, in_width, in_channels] = [1, 28, x, 5]
# [filter_height, filter_width, in_channels, out_channels] = [3, 3, 5, 10]
# y_cnna_time = []
# for x in range(5,33):
# 	cnna_parameter = [28, x, 3, 3, 10]
# 	y_cnna_time.append(cnna_calculated_time(cnna_parameter))
# x_neuron_width = list(range(5,33))

# plt.figure(4)
# plt.plot(x_neuron_width, y_cnna_time, 'ro')
# plt.xlabel('neuron activation width')
# plt.ylabel('total clocks')
# plt.show()