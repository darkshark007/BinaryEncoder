import 'EncoderBase.dart';
import 'dart:async';
import '../IO.dart';

class EncoderReverse implements Encoder {

	String encoderKey = "XMPLREVE";
	String encoderDescription = "Reverses the data";

	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		StreamController outputStream = new StreamController<List<int>>();
		List<Stream<List<int>>> streams = new List();

		// Do Stuff with the stream input
		void process(List<int> newInput) async {
			if (newInput == null) return;

			StreamController tmpStreamController = new StreamController<List<int>>()
				..add(newInput);
			Stream tmpStream = readWriteTempFile(tmpStreamController.stream, (List<int> _) {});
			streams.add(tmpStream);
			tmpStreamController.close();
		}

		input.listen(process, onDone: () async {
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

	@override
	Stream<List<int>> decode(Stream<List<int>> input) => encode(input);
}