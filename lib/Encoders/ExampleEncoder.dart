import 'EncoderBase.dart';
import 'dart:async';

class ExampleEncoder implements Encoder {

	String encoderKey = "XMPLENCO";
	String encoderDescription = "Example Encoder in -> out";

	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		StreamController outputStream = new StreamController<List<int>>();
		bool isDone = false;

		// Do Stuff with the stream input
		void process(List<int> newInput) async {
			if (isDone) {
				// Do cleanup stuff
			}
			if (newInput == null) return;

			outputStream.add(newInput);
		}

		input.listen(process, onDone: () async {
			isDone = true;
			await process(null);
			outputStream.close();
		});

		return outputStream.stream;
	}

	@override
	Stream<List<int>> decode(Stream<List<int>> input) {
		StreamController outputStream = new StreamController<List<int>>();
		bool isDone = false;

		// Do Stuff with the stream input
		void process(List<int> newInput) async {
			if (isDone) {
				// Do cleanup stuff
			}
			if (newInput == null) return;

			outputStream.add(newInput);
		}

		input.listen(process, onDone: () async {
			isDone = true;
			await process(null);
			outputStream.close();
		});

		return outputStream.stream;
	}
}