import 'package:dbcrypt/dbcrypt.dart';
import 'package:postgres/postgres.dart';

import 'package:cmt_projekt/constants.dart';
import 'package:cmt_projekt/environment.dart';

/// Creates queries and communicates with the database which allows for Orm usage.
class DatabaseQueries {
  /// Creates a db connection based on values from environment.dart
  var connection = PostgreSQLConnection(dbConnection, dbPort, dbDatabase,
      username: dbUser, password: dbPassword);

  /// opens a database connection using [connection]
  DatabaseQueries() {
    init();
  }

  void init() async {
    await connection.open();
  }

  /// compares a the password to the user's on the db, on fail null is returned
  /// otherwise a obj of account info is returned.
  Future<Map<String, dynamic>?> compareCredentials(String login, String pass) async {
      final results = await connection.mappedResultsQuery(
          "SELECT password FROM Account WHERE (email = '$login' OR phone = '$login')");
      if (results.length == 1 && DBCrypt().checkpw(pass, results[0]["account"]!["password"] as String)) {
        return getAccount(login);
      }
      return null;
  }
  /// Query database to find if any account are connected to a given email address or phone number
  Future<bool> checkLogin(String login) async {
    final checkUserInput = await connection.mappedResultsQuery(
        "SELECT email FROM Account WHERE (email = '$login' OR phone = '$login')");
    if (checkUserInput.isNotEmpty) {
      return true;
    }else{
      return false;
    }
  }

  /// Tries to create a new account in the db, if there are conflicts then a [PostgreSQLException] is thrown.
  Future<Map<String, dynamic>> createAccount(String email, String pass, String phone, String username) async {
      await connection
          .query("INSERT INTO Account VALUES('$email', '$pass', '$phone', '$username')");
      return (getAccount(email));
  }

  /// Gets account info based on the search parameter, if nothing is found then an [Exception] is thrown.
  Future<Map<String, dynamic>> getAccount(String login) async {
      final results = await connection.mappedResultsQuery(
          "SELECT email, uid, phone, username FROM Account WHERE ((email = '$login' OR phone = '$login'))");

      if (results.isEmpty) {
        throw Exception("Account does not exist");
      }

      return results[0]['account'] as Map<String, dynamic>;
  }

  /// sets a channel to offline whom matches the supplies channelid
  Future<void> goOffline(String uid) async {
    try {
      await connection.query(
          "UPDATE Channel SET isonline = false WHERE channelid = '$uid'");
    } on PostgreSQLException catch (e) {
      logger.e("error in goOffline\n" + (e.message ?? ""), [e, e.stackTrace]);
    }
  }

  /// creates a channel and attaches it to the user account with the supplies uid
  Future<void> createChannel(String channelName, String uid, String category) async {
      await connection.query(
          "INSERT INTO channelview VALUES('$uid','$channelName','$category')");
  }

  /// Gets a list of available channels that are live
  Future<List<Map<String, dynamic>>> getOnlineChannels() async {
      final results = await connection.mappedResultsQuery(
          "SELECT category, channelid, channelname, isonline, username, (SELECT COUNT('*') as total FROM Viewers WHERE channel = channelid) "
              "FROM Channel JOIN Account on uid = channelid WHERE isonline = true;");

      List<Map<String, dynamic>> response = [];

      for(final row in results){
        Map<String, dynamic> m = {};
        m.addAll(row[""]!);
        m.addAll(row["account"]!);
        m.addAll(row["channel"]!);
        response.add(m);
      }

      return response;
  }

  /// gets data of a single channel using the uid, throws an exception if none is found.
  Future<Map<String, dynamic>> getChannel(String uid) async{
    final result = await connection.mappedResultsQuery(
        "SELECT category, channelid, channelname, isonline, username, (SELECT COUNT('*') as total FROM Viewers WHERE channel = channelid) "
            "FROM Channel JOIN Account on uid = channelid WHERE channelid = '$uid';");

    if(result.isEmpty){
      throw Exception("Channel not found");
    }

    Map<String, dynamic> m = {};
    m.addAll(result[0][""]!);
    m.addAll(result[0]["account"]!);
    m.addAll(result[0]["channel"]!);

    return m;
  }

  /// adds a viewer to an online channel
  Future<void> insertViewer(String uid, String channelId) async{
      await connection.query(
          "INSERT INTO Viewers VALUES('$uid','$channelId')");
  }

  /// removes a viewer from an online channel
  Future<void> delViewer(String uid, String channelId) async{
      await connection.query(
          "DELETE FROM Viewers WHERE(viewer = '$uid' AND channel = '$channelId')");
  }

  /// clears all viewers from a channel
  Future<void> delViewers(String channelId) async{
      await connection.query(
          "DELETE FROM Viewers WHERE(channel = '$channelId')");
  }

}