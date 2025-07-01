import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/androidpublisher/v3.dart';

Future<void> main(List<String> arguments) async {
  const scopes = ['https://www.googleapis.com/auth/androidpublisher'];

  if (arguments.length < 3) {
    throw ArgumentError(
      'You should pass arguments in order: [packageName] [bundleFilePath] [jsonKeyFilePath]',
    );
  }

  final packageName = arguments[0];
  final bundleFilePath = arguments[1];
  final jsonKeyFilePath = arguments[2];
  bool? changesNotSentForReview;

  if (arguments.length >= 4) {
    changesNotSentForReview = bool.tryParse(arguments[3]);
  }


  try {
    final jsonKey = File(jsonKeyFilePath).readAsStringSync();
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonKey);

    final authClient = await clientViaServiceAccount(
      accountCredentials,
      scopes,
    );

    final appPublisher = AndroidPublisherApi(authClient);

    print('Started creating edit');

    final edit = await appPublisher.edits.insert(AppEdit(), packageName);
    final editId = edit.id!;

    print('Finished creating edit');

    final file = File.fromUri(Uri.parse(bundleFilePath));
    final stream = file.openRead();
    final length = await file.length();

    print('Started uploading bundle');

    await appPublisher.edits.bundles.upload(
      packageName,
      editId,
      uploadMedia: Media(stream, length),
    );

    print('Finished uploading bundle');
    print('Started commiting edit');

    await appPublisher.edits.commit(
      packageName,
      editId,
      changesNotSentForReview: changesNotSentForReview,
    );
    print('Finished commiting edit');

    exit(0);
  } catch (exc) {
    print(exc);
    exit(1);
  }
}
