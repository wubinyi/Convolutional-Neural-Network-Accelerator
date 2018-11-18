Platform: Tensorflow R1.2
	  Python 3.6.0

"cnn_tensorflow_model" --> used to save a cnn model without quantizating

How to quantizate --> use command "bazel-bin/tensorflow/tools/quantization/quantize_graph 
				   --input=/home/wubinyi/Machine_Learning_NN/Tensorflow/saved_model/cnn_sa_test.pb 
				   --output_node_name="Y1" --print_node 
				   --output=/home/wubinyi/Machine_Learning_NN/Tensorflow/quantization_model/cnn_sa_test_quantizate.pb 
				   --mode=eightbit"

"cnn_tensorflow_model_restore" --> used to restore a quantizated cnn model, give a input(random, feature map) and store all computation node's data

"cnna_cnn_quantization_test" --> used to validate CNNA, read data saved by "cnn_tensorflow_model_restore" and map them into CNNA.


folder "model_parameter" --> store the quantizated CNN model