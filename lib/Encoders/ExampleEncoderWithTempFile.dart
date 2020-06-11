import 'EncoderBase.dart';
import 'dart:async';
import '../IO.dart';

// This encoder serves as an example/template for what an encoder implementation with Temp Files might look like.  It doesn't perform any operation on data, input is passed through as output.
class ExampleEncoderWithTempFile implements Encoder {

	String encoderKey = "XMPLTEMP";
	String encoderDescription = "Example Encoder With a Temp File";

	var id = 0;
	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		var myId = id++;
		StreamController outputStream = new StreamController<List<int>>();
		bool isDone = false;

		// Do Stuff with the stream input
		void processPass1(List<int> newInput) async {
			if (isDone) {
				// Do cleanup stuff
			}
			if (newInput == null) return;

			print('Outputting p1.${myId}!!! ${newInput}');
		}

		// Do Stuff with the stream input
		void processPass2(List<int> newInput) async {
			if (isDone) {
				// Do cleanup stuff
			}
			if (newInput == null) return;

			print('Outputting p2.${myId}!!! ${newInput}');
			outputStream.add(newInput);
		}

		readWriteTempFile(input, processPass1)
				.listen(processPass2, onDone: () async {
			isDone = true;
			await processPass2(null);
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