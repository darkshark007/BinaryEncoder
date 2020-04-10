import 'dart:io';
import 'dart:async';
import 'dart:convert';


Future<File> getFile(String message, bool shouldExist) async {
  stdout.write("${message}\n> ");
  var token = stdin.readLineSync();
  var file = new File(token);

  // Check if the file exists
  if (shouldExist) {
   if (!await file.exists()) {
     stdout.write("That file doesn't exist!\n\n");
     return await getFile(message, shouldExist);
   } else {
     return file;
   }
  } else {
   if (await file.exists()) {
     if (await getBool("Warning!  That file already exists, overwrite?")) {
       return file;
     } else {
       return await getFile(message, shouldExist);
     }
   }
  }
}

Future<bool> getBool(String message) async {
  stdout.write("${message}\n> ");
  var token = stdin.readLineSync();
  switch (token) {
    case 'Y':
    case 'y':
    case 'Yes':
    case 'yes':
    case 'T':
    case 't':
    case 'True':
    case 'true':
      return true;
    case 'N':
    case 'n':
    case 'No':
    case 'no':
    case 'F':
    case 'f':
    case 'False':
    case 'false':
      return false;
    default:
      stdout.write("Invalid input\n\n");
      return await getBool(message);
  }
}

Future<int> getInt(String message, {int min: null, int max: null}) async {
  stdout.write("${message}\n> ");
  var token = stdin.readLineSync();
  try {
    int result = int.parse(token);
    if (min != null && result < min) {
      stdout.write("Value is less than minimum!($min)\n\n");
      return await getInt(message,min: min,max: max);
    }
    if (max != null && result > max) {
      stdout.write("Value is greater than maximum!($max)\n\n");
      return await getInt(message,min: min,max: max);
    }
    return result;
  } on FormatException catch(e) {
    stdout.write("Invalid integer\n\n");
    return await getInt(message,min: min,max: max);
  }
}

String getString(String message) {
  stdout.write("${message}\n> ");
  return stdin.readLineSync();
}

void writeFile(File outputFile, Stream<List<int>> outputStream) {
	var writeStream = outputFile.openWrite();
	outputStream.listen((List<int> out) {
	  if (out != null) writeStream.add(out);
	}, onDone: () {
		writeStream.close();
	});
}

Stream<List<int>> readFile(File outputFile) {
  Stream<List<int>> inputStream = outputFile.openRead();
  return inputStream;
}

int tmpCount = 0;
Stream<List<int>> readWriteTempFile(Stream<List<int>> inputStream, TaskRunner handler) {
  var fileCount = tmpCount++;
  var fileName = 'tmp${fileCount}.tmp';
  var outFile = File(fileName);

  // Read back file
  StreamController readStream = new StreamController<List<int>>();

  // Write the output file
  var writeStream = outFile.openWrite();
	inputStream.listen((List<int> out) {
	  handler(out);
//	  print("Outputting wf.${fileCount}");
	  if (out != null) writeStream.add(out);
	}, onDone: () async {
		await writeStream.close();
		handler(null);
    Stream<List<int>> inputFileStream = outFile.openRead();
    inputFileStream.listen((List<int> data) {
//  	  print("Outputting rf.${fileCount}");
      readStream.add(data);
    }, onDone: () {
      readStream.close();
      outFile.delete();
    });
	});

  return readStream.stream;
}

typedef TaskRunner = void Function(List<int> data);