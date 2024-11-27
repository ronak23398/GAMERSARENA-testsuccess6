import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static final Client client = Client();
  static final Storage storage = Storage(client);

  static void init() {
    client
        .setEndpoint(
            'https://cloud.appwrite.io/console/project-67470eed0010f00a59fa/overview/platforms') 
        .setProject('67470eed0010f00a59fa')
        .setSelfSigned(status: true); 
  }
}
