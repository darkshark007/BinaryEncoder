import 'EncoderBase.dart';
import 'dart:async';
import '../IO.dart';

// This encoder takess in data and encodes it by bitmasking it with a password stored in the output data.
class EncoderEmbeddedPassword implements Encoder {

	String encoderKey = "PASSEMBD";
	String encoderDescription = "Encoder Using an embedded Password";

	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		StreamController<List<int>> encodeStream = new StreamController();
		String password = getString("Password?");
		// Write the password to the output stream.  This allows the decoder to decode the file without the user needing to know what the key was.
		// This is NOT a very secure practice, and should not be relied upon to be so.
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
			// The emebedded password should be the first bit of data in the stream, will need to get that up front.
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

// This encoder takess in data and encodes it by bitmasking it with a password that is known only at encoding time.
class EncoderPassword implements Encoder {

	String encoderKey = "PASSWORD";
	String encoderDescription = "Encoder Using a secret Password";

	@override
	Stream<List<int>> encode(Stream<List<int>> input) {
		StreamController<List<int>> encodeStream = new StreamController();
		String password = getString("Password?");
		encodeStream.add(password.codeUnits);
		input.listen((List<int> data) => encodeStream.add(data), onDone: () => encodeStream.close());

		return encodeWithPasswordMask(encodeStream.stream);
	}

	// The decoding process for this algorithm is the same as the encoding process.
	@override
	Stream<List<int>> decode(Stream<List<int>> input) => encode(input);
}


// This function creates a stream proxy which masks any data that comes through the sream with the given password.
@override
Stream<List<int>> encodeWithPasswordMask(Stream<List<int>> input) {
	StreamController outputStream = new StreamController<List<int>>();
	bool passwordRetrieved = false;
	List<int> password;
	int passwordIdx = 0;

	input.listen((List<int> data) {
		// The password to use to mask should be the first bit of data in the stream, will need to get that up front.
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