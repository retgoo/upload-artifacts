import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:github_actions_toolkit/github_actions_toolkit.dart' as gaction;

void main(List<String> args) async {
  exitCode = 0;

  final logger = gaction.log;

  final path = gaction.Input('path', isRequired: true, canBeEmpty: false);
  logger.info('path: ${path.value}');

  final zip = gaction.Input('zip', isRequired: false);
  logger.info('zip: ${zip.value}');

  final root = gaction.Input('root', isRequired: false);
  logger.info('is root folder: ${root.value}');

  final output = gaction.Input('output', isRequired: false);
  logger.info('zip file name: ${output.value}');

  final id = gaction.Input('id', isRequired: true, canBeEmpty: false);
  logger.info('id: ${id.value}');

  final srcPath = path.value;

  File data;
  if (zip.value == 'true') {
    print('Zipping data');
    final encoder = ZipFileEncoder();
    encoder.create(output.value);
    encoder.addDirectory(Directory(srcPath),
        includeDirName: root.value == 'true');
    encoder.close();

    data = File(output.value);
  } else {
    data = File(srcPath);
  }

  final dio = Dio(
    BaseOptions(baseUrl: 'https://api.storage.retgoo.id/'),
  );

  final response = await dio.post(
    (id.value?.isEmpty ?? true) ? 'share' : 'share/${id.value}',
    data: FormData.fromMap(
      {
        'file': await MultipartFile.fromFile(data.absolute.path),
      },
    ),
  );

  if (response.statusCode == 200 && response.data['success']) {
    gaction.setOutput('fileId', response.data['id']);
    logger.info('artifact uploaded: ${response.data['id']}');
  }
}
