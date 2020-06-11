import 'EncoderBase.dart';
import 'dart:async';
import '../IO.dart';

// This encoder takess in data and encodes it by outputting it in reverse order.
class EncoderReverse implements Encoder {

	String encoderKey = "XMPLREVE";
	String encoderDescription = "Reverses the data";

	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		StreamController outputStream = new StreamController<List<int>>();
		List<Stream<List<int>>> streams = new List();

		// We cant start outputting the data until we reach the end, because we need to start at the end, so for now we will take input data we see and write it to temp files until we get to the end.
		void process(List<int> newInput) async {
			if (newInput == null) return;

			StreamController tmpStreamController = new StreamController<List<int>>()
				..add(newInput);
			Stream tmpStream = readWriteTempFile(tmpStreamController.stream, (List<int> _) {});
			streams.add(tmpStream);
			tmpStreamController.close();
		}

		input.listen(process, onDone: () async {
			// Once the input stream completes, start reading the data we saved to temp files in the reverse order and outputting it
			var idx = 0;
			void readStream(Stream<List<int>> stream) {
				stream.listen((List<int> data) => outputStream.add(data.reversed.toList()), onDone: () {
					if (idx == streams.length) {
						outputStream.close();
					} else {
						readStream(streams[idx++]);
					}
				});
			}
			streams = streams.reversed.toList();
			readStream(streams[idx++]);
		});

		return outputStream.stream;
	}

	// The decoding process for this algorithm is the same as the encoding process.
	@override
	Stream<List<int>> decode(Stream<List<int>> input) => encode(input);
}