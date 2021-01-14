import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:dio/dio.dart';

void main(List<String> args) async {
  exitCode = 0;

  bool zipFirst = false;
  bool isRoot = false;
  final parser = ArgParser()
    ..addFlag("zip",
        negatable: false,
        abbr: 'z',
        defaultsTo: false,
        callback: (value) => zipFirst = value)
    ..addFlag(
      "root",
      negatable: false,
      abbr: "r",
      defaultsTo: false,
      callback: (value) => isRoot = value,
    )
    ..addOption("output", abbr: "o")
    ..addOption("id", abbr: "i");

  final argResults = parser.parse(args);

  File data;

  final fileID = argResults["id"];
  final srcPath = args.last;

  if (zipFirst) {
    print("Zipping data");
    final output = argResults["output"];
    final encoder = ZipFileEncoder();
    encoder.create(output);
    encoder.addDirectory(Directory(srcPath), includeDirName: isRoot);
    encoder.close();

    data = File(output);
  } else {
    data = File(srcPath);
  }

  Dio dio = Dio(
    BaseOptions(baseUrl: "https://api.storage.retgoo.id/share/"),
  );

  final response = await dio.post(
    fileID,
    data: FormData.fromMap(
      {
        "file": await MultipartFile.fromFile(data.absolute.path),
      },
    ),
  );

  if (response.statusCode == 200) {
    print("artifact uploaded");
  }
}
