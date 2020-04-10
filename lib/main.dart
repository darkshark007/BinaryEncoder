import 'dart:async';
import 'dart:io';
import 'IO.dart';
import 'dart:math';

// Encoders
import 'Encoders/EncoderBase.dart';
import 'Encoders/ExampleEncoder.dart';
import 'Encoders/ExampleEncoderWithTempFile.dart';
import 'Encoders/EncoderReverse.dart';
import 'Encoders/EncoderPassword.dart';

var decoderList = {};
var decoderIndex = 0;
void main() async {

	// Build the list of decoders
	decoderList[decoderIndex++] = new ExampleEncoder();
	decoderList[decoderIndex++] = new ExampleEncoderWithTempFile();
	decoderList[decoderIndex++] = new EncoderReverse();
	decoderList[decoderIndex++] = new EncoderPassword();
	decoderList[decoderIndex++] = new EncoderEmbeddedPassword();
	for (var i = 0; i < decoderIndex; i++ ) {
		if (decoderList[decoderList[i].encoderKey] != null) {
			print('ERROR, EncoderKey already exists ${decoderList[i].encoderKey}');
		} else {
			if (decoderList[i].encoderKey.length != 8) {
				print('ERROR, EncoderKey incorrect length ${decoderList[i].encoderKey}');
			}
			decoderList[decoderList[i].encoderKey] = decoderList[i];
		}
	}

	int operation = await getInt(
			"Perform Operation:\n[0] Encode\n[1] Decode\n[2] Fill",
			min: 0,
			max: 2);

	if (operation == 2) {
		fill();
	} else {
		File fileIn = await getFile("Input file:", true);


		if (operation == 0) encode(fileIn);
		if (operation == 1) decode(fileIn);
	}

}


void encode(File fileIn) async {
	Stream<List<int>> inputStream = readFile(fileIn);
	StreamController<List<int>> encodeStream = new StreamController();
	Stream<List<int>> tmpOutStream = encodeStream.stream;

	var encoderString = "";
	for (var i = 0; i < decoderIndex; i++ )
		encoderString += "[$i] ${(decoderList[i] as Encoder).encoderDescription}\n";

	bool cont = true;
	String encodings = "";
	while (cont) {
		int encoder = await getInt("Select Encoder:\n${encoderString}\n> ", min: 0, max: (decoderIndex-1));

		print('Encoding with encoder ${decoderList[encoder].encoderKey}');
		tmpOutStream = decoderList[encoder].encode(tmpOutStream);
		encodings = decoderList[encoder].encoderKey+encodings;


		cont = await getBool("Encode Again?");
	}

	String fileName = fileIn.path.split("/").last;
	encodeStream.add("${fileName}|".codeUnits);
	inputStream.listen((List<int> data) => encodeStream.add(data), onDone: () => encodeStream.close());


	File outFile = File('EncodedFile.txt');
	var writeStream = outFile.openWrite();
	writeStream.add("${encodings}|".codeUnits);
	tmpOutStream.listen((List<int> data) => writeStream.add(data), onDone: () => writeStream.close());
}

void decode(File fileIn) {
	Stream<List<int>> inputStream = readFile(fileIn);
	StreamController<List<int>> encodeStream = new StreamController();
	StreamController<List<int>> writeStream = new StreamController();
	Stream<List<int>> tmpOutStream = encodeStream.stream;

	bool decodersAreSetUp = false;
	bool outputFileIsSetUp = false;
	inputStream.listen((List<int> data) {
		if (!decodersAreSetUp) {
			decodersAreSetUp = true;
			while (String.fromCharCode(data[0]) != "|") {
				String key = String.fromCharCodes(data.sublist(0,8));
				data = data.sublist(8);
				print('Decoding with decoder ${key}');
				tmpOutStream = decoderList[key].decode(tmpOutStream);
			}
			data = data.sublist(1);

			tmpOutStream.listen((List<int> data) {
				if (!outputFileIsSetUp) {
					outputFileIsSetUp = true;
					String fileName = "";
					while (String.fromCharCode(data[0]) != "|") {
						fileName += String.fromCharCode(data[0]);
						data = data.sublist(1);
					}
					data = data.sublist(1);
					writeFile(File(fileName),writeStream.stream);
				}
				writeStream.add(data);
			}, onDone: () => writeStream.close());
		}
		encodeStream.add(data);
	}, onDone: () => encodeStream.close());

}

void fill() async {
	double convRatio = 68403.473613894455578;
	int diskSpace = await getInt("Free disk space? (GB)");
	int diskConverted = (((diskSpace*0.95)-10) * convRatio).floor();
	List<File> tmpFiles = new List();
	int fileSize = 10000;
	int iteration = 2;
	int diskUsed = 0;
	void writeFile(File file) async {
		tmpFiles.add(file);
		diskUsed += fileSize;
		var outStream = file.openWrite();
		Random r = new Random();
		List<String> output = new List(100);
		for (var i = 0; i < 100; i++ ) {
			List<int> tmpList = new List(10000);
			for (var i2 = 0; i2 < 10000; i2++ ) {
				tmpList[i2] = r.nextInt(255);
			}
			output[i] = String.fromCharCodes(tmpList);
		}
		try {
			for (var i = 0; i < fileSize; i++ ) {
				outStream.write(output[r.nextInt(100)]);
			}
		} on Exception catch(e) {
			print('Exception! ${e}');
		}
		await outStream.close();
	}
	for ( var i = 0; i < 3000; i++) {
		if (diskUsed > diskConverted) {
			tmpFiles.forEach((File f) => f.delete());
			tmpFiles = new List();
			diskUsed = 0;
			iteration--;
			if (iteration <= 0) return;
		}

		// Update sizes
		fileSize = ((diskConverted-diskUsed)/4).floor();
		fileSize = max(fileSize, 100);
		fileSize = min(fileSize, 1000000);
		print('Using size \nfileSize: ${fileSize}\n~${fileSize*1024/convRatio}MB');

		writeFile(File('Temp${i++}.tmp'));
		writeFile(File('Temp${i++}.tmp'));
		await writeFile(File('Temp${i}.tmp'));
	}
}