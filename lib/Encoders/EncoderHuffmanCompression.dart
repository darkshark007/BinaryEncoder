import 'EncoderBase.dart';
import 'dart:async';
import '../IO.dart';

// This encoder takess in data and encode/compresses it using a Huffman Tree Compression Algorithm.
class EncoderHuffmanCompression implements Encoder {

	String encoderKey = "HUFFCOMP";
	String encoderDescription = "Compress a file using a Huffman Tree Compression Algorithm";

	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		StreamController outputStream = new StreamController<List<int>>();
		List<Stream<List<int>>> streams = new List();

		// We cant start outputting the data until we reach the end, so for now we will take input data we see and write it to temp files until we get to the end.
		Map<int, int> dataMap = {};
		void process(List<int> newInput) async {
			if (newInput == null) return;

			StreamController tmpStreamController = new StreamController<List<int>>()
				..add(newInput);
			Stream tmpStream = await readWriteTempFile(tmpStreamController.stream, (List<int> _) {});
			streams.add(tmpStream);
			tmpStreamController.close();

			if (input != null) {
				// Collect info about the frequency of particular data fragments as we pre-process.
				for (int val in newInput) {
					if (dataMap[val] == null) {
						dataMap[val] = 0;
					}
					dataMap[val]++;
				}
			}
		}

		var encodedBuffer = "";
		input.listen(process, onDone: () async {
			// Build the Huffman Tree now that we've processed all the data
			var tree = buildHuffmanTreeFromDataMap(dataMap);
			// Encode the tree and store it in the file for decoding
			// Start with the number of keys we have to encode, so we know how many to expect
			encodedBuffer += (tree['strToEncodingMap'].length).toRadixString(2).padLeft(8,'0');
			tree['strToEncodingMap'].forEach((key, val) {
				// For each key, add:
				// The key itself
				encodedBuffer += key.toRadixString(2).padLeft(8,'0');
				// The length of the encoded string, as a 4-bit string (It could be 1-15 bits long)
				encodedBuffer += (val.length-1).toRadixString(2).padLeft(4,'0');
				// The encoded string
				encodedBuffer += val;
			});

			// Once the input stream completes, start reading the data we saved to temp files in the reverse order and outputting it
			var idx = 0;
			void readStream(Stream<List<int>> stream) {
				stream.listen(
					(List<int> data) {
						List<int> encodedData = [];
						for (int val in data) {
							encodedBuffer += tree['strToEncodingMap'][val];
							while (encodedBuffer.length > 16) {
								// Slice off 8 bits
								var substring = encodedBuffer.substring(0,8);
								encodedBuffer = encodedBuffer.substring(8);
								encodedData.add(int.parse(substring, radix: 2));
							}
						}
						outputStream.add(encodedData);
					}, onDone: () {
						if (idx == streams.length) {
							// Flush out the rest of the buffer and close out the file
							List<int> encodedData = [];

							// The last encoded bits may not constitute a full byte, so we may need to pad it.
							int padding = (8-encodedBuffer.length) % 8;
							encodedBuffer += "0"*padding;
							while (encodedBuffer.length > 0) {
								// Slice off 8 bits
								var substring = encodedBuffer.substring(0,8);
								encodedBuffer = encodedBuffer.substring(8);
								encodedData.add(int.parse(substring, radix: 2));
							}
							// Add the padding to the end of the file so we know how much to take off at decode time
							encodedData.add(padding);

							outputStream.add(encodedData);
							outputStream.close();
						} else {
							readStream(streams[idx++]);
						}
					}
				);
			}
			streams = streams.reversed.toList();
			readStream(streams[idx++]);
		});

		return outputStream.stream;
	}

	// TODO: Implement Decode Function
	@override
	Stream<List<int>> decode(Stream<List<int>> input) => throw UnimplementedError('This isnt implemented yet');
}


buildHuffmanTreeFromDataMap(dataMap) {

	getNode(str, count) {
		return {
			'nodeString': str,
			'count': count,
			'refString': "",
			'0': null,
			'1': null,
			'parent': null,
			'bitsCount': 0,
		};
	}

	var initialNodeList = [];
	dataMap.forEach((key, val) => initialNodeList.add(getNode(key, val)));

	var resultContext = {};
	resultContext['dataMap'] = dataMap;
	resultContext['initialNodeList'] = initialNodeList;
	resultContext['strToEncodingMap'] = {};

	var nodeList = [];
	resultContext['nodeList'] = nodeList;
	for (var nIdx = 0; nIdx < initialNodeList.length; nIdx++) {
		nodeList.add(initialNodeList[nIdx]);
	}

	while (nodeList.length > 1) {
		nodeList.sort((a, b) => a['count']-b['count']);
		var first = nodeList.removeAt(0);
		var second = nodeList.removeAt(0);
		var newNode = getNode(null, first['count']+second['count']);
		newNode['0'] = first;
		newNode['1'] = second;
		first['parent'] = newNode;
		second['parent'] = newNode;
		nodeList.add(newNode);
	}
	resultContext['root'] = nodeList[0];

	// Trace all nodes back
	for (var nIdx = 0; nIdx < initialNodeList.length; nIdx++) {
		var currentNode = initialNodeList[nIdx];
		var refString = "";
		var traceNode = currentNode;
		while (traceNode['parent'] != null) {
			var parent = traceNode['parent'];
			if (parent['0'] == traceNode) refString = "0"+refString;
			if (parent['1'] == traceNode) refString = "1"+refString;
			traceNode = parent;
		}
		currentNode['refString'] = refString;
		currentNode['bitsCount'] = (refString.length*currentNode['count']);
		resultContext['strToEncodingMap'][currentNode['nodeString']] = currentNode['refString'];
	}


	return resultContext;
}