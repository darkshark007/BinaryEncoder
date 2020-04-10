import 'EncoderBase.dart';
import 'dart:async';
import '../IO.dart';

class EncoderEmbeddedPassword implements Encoder {

	String encoderKey = "PASSEMBD";
	String encoderDescription = "Example Encoder Using an embedded Password";

	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		StreamController<List<int>> encodeStream = new StreamController();
		String password = getString("Password?");
		encodeStream.add(password.codeUnits);
		input.listen((List<int> data) => encodeStream.add(data), onDone: () => encodeStream.close());

		Stream<List<int>> tmpStream = encodeWithPasswordMask(encodeStream.stream);


		StreamController<List<int>> outStream = new StreamController();
		outStream.add("${password}|".codeUnits);
		tmpStream.listen((List<int> data) => outStream.add(data), onDone: () => outStream.close());
		return outStream.stream;
	}

	@override
	Stream<List<int>> decode(Stream<List<int>> input) {
		StreamController<List<int>> outStream = new StreamController();
		bool passwordRetrieved = false;
		input.listen((List<int> data) {
			if (!passwordRetrieved) {
				passwordRetrieved = true;
				String password = "";
				while (String.fromCharCode(data[0]) != "|") {
					password += String.fromCharCode(data[0]);
					data = data.sublist(1);
				}
				data = data.sublist(1);
				outStream.add(password.codeUnits);
			}
			outStream.add(data);
		}, onDone: () => outStream.close());
		return encodeWithPasswordMask(outStream.stream);
	}
}

class EncoderPassword implements Encoder {

	String encoderKey = "PASSWORD";
	String encoderDescription = "Example Encoder Using a secret Password";

	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		StreamController<List<int>> encodeStream = new StreamController();
		String password = getString("Password?");
		encodeStream.add(password.codeUnits);
		input.listen((List<int> data) => encodeStream.add(data), onDone: () => encodeStream.close());

		return encodeWithPasswordMask(encodeStream.stream);
	}

	@override
	Stream<List<int>> decode(Stream<List<int>> input) => encode(input);
}



@override
Stream<List<int>> encodeWithPasswordMask(Stream<List<int>> input) {
	StreamController outputStream = new StreamController<List<int>>();
	bool passwordRetrieved = false;
	List<int> password;
	int passwordIdx = 0;

	input.listen((List<int> data) {
		if (!passwordRetrieved) {
			passwordRetrieved = true;
			password = data;
			print('  Masking with password \'${String.fromCharCodes(password)}\'');
			return;
		}

		data = data.map((int n) {
			int result = n ^ password[passwordIdx];
			passwordIdx = (passwordIdx + 1) % password.length;
			return result;
		}).toList();
		outputStream.add(data);
	}, onDone: () => outputStream.close());
	return outputStream.stream;
}