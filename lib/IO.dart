import 'dart:io';
import 'dart:async';
import 'dart:convert';


// Prompt the user for a Filename
Future<File> getFile(String message, bool shouldExist) async {
  stdout.write("${message}\n> ");
  var token = stdin.readLineSync();
  var file = new File(token);

  // Check if the file exists
  if (shouldExist) {
   if (!await file.exists()) {
     stdout.write("That file doesn't exist!\n\n");
      // Recursively prompt if we expect that the file should exist, but it doesn't or we couldn't find it
     return await getFile(message, shouldExist);
   } else {
     return file;
   }
  } else {
   if (await file.exists()) {
      // If we expect that the file shouldn't already exist (for example, we want to write a new file) but it DOES, prompt the user to overwrite.
     if (await getBool("Warning!  That file already exists, overwrite?")) {
       return file;
     } else {
      // Recursively prompt if we don't want to overwrite an existing file
       return await getFile(message, shouldExist);
     }
   }
  }
}

// Prompt the user for a Boolean-type input
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
      // Recursively prompt if there's a problem until we get valid input
      return await getBool(message);
  }
}

// Prompt the user for a Int-type input, optionally within a specific range
Future<int> getInt(String message, {int min: null, int max: null}) async {
  stdout.write("${message}\n> ");
  var token = stdin.readLineSync();
  try {
    int result = int.parse(token);
    if (min != null && result < min) {
      stdout.write("Value is less than minimum!($min)\n\n");
      // Recursively prompt if there's a problem until we get valid input
      return await getInt(message,min: min,max: max);
    }
    if (max != null && result > max) {
      stdout.write("Value is greater than maximum!($max)\n\n");
      // Recursively prompt if there's a problem until we get valid input
      return await getInt(message,min: min,max: max);
    }
    return result;
  } on FormatException catch(e) {
    stdout.write("Invalid integer\n\n");
      // Recursively prompt if there's a problem until we get valid input
    return await getInt(message,min: min,max: max);
  }
}

// Prompt the user for a num-type input, optionally within a specific range
Future<num> getNum(String message, {num min: null, num max: null}) async {
  stdout.write("${message}\n> ");
  var token = stdin.readLineSync();
  try {
    num result = num.parse(token);
    if (min != null && result < min) {
      stdout.write("Value is less than minimum!($min)\n\n");
      // Recursively prompt if there's a problem until we get valid input
      return await getNum(message,min: min,max: max);
    }
    if (max != null && result > max) {
      stdout.write("Value is greater than maximum!($max)\n\n");
      // Recursively prompt if there's a problem until we get valid input
      return await getNum(message,min: min,max: max);
    }
    return result;
  } on FormatException catch(e) {
    stdout.write("Invalid num\n\n");
      // Recursively prompt if there's a problem until we get valid input
    return await getNum(message,min: min,max: max);
  }
}

// Prompt the user for a String-type input, optionally within a specific range
String getString(String message) {
  stdout.write("${message}\n> ");
  return stdin.readLineSync();
}

// Write the output from a given stream to the given file
void writeFile(File outputFile, Stream<List<int>> outputStream) {
	var writeStream = outputFile.openWrite();
	outputStream.listen((List<int> out) {
	  if (out != null) writeStream.add(out);
	}, onDone: () {
		writeStream.close();
	});
}

// Open a stream for the given file to read the contents
Stream<List<int>> readFile(File inputFile) {
  Stream<List<int>> inputStream = inputFile.openRead();
  return inputStream;
}


// Wrapper handler for managing a Temp file.
// Takes a stream as input, which should contain the content to write to the temp file.
// Returns a stream.  Once the input stream as finished, this stream will read back the contents written to the temp file.
// Once the output stream has been consumed, the temp file will close and be removed.
// Optionally, a function handler can be passed in which will be called with the data from the input stream.  This can be useful for pre-processing.
// TODO: What was the usecase for the taskhandler, again?
int tmpCount = 0;
Stream<List<int>> readWriteTempFile(Stream<List<int>> inputStream, TaskRunner handler) {
  // TODO: Can I/Should I put a limit on number of tmp files open at one time?
  var fileCount = tmpCount++;
  var fileName = 'tmp${fileCount}.tmp';
  var outFile = File(fileName);

  // Read back file
  StreamController readStream = new StreamController<List<int>>();

  // Write the output file
  var writeStream = outFile.openWrite();
	inputStream.listen((List<int> out) {
	  handler(out);
	  if (out != null) writeStream.add(out);
	}, onDone: () async {
    // The input stream has completed, so start writing the output stream
		await writeStream.close();
		handler(null);
    Stream<List<int>> inputFileStream = outFile.openRead();
    inputFileStream.listen((List<int> data) {
      readStream.add(data);
    }, onDone: () {
      // Clean up the temp file
      readStream.close();
      outFile.delete();
    });
	});

  return readStream.stream;
}

// Defines a generic function handler which operates on a chunk of data
typedef TaskRunner = void Function(List<int> data);