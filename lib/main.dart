import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'record.dart';
import 'dart:async';

void main() => runApp(MyApp());


Future<RemoteConfig> setupRemoteConfig() async {
  final RemoteConfig remoteConfig = await RemoteConfig.instance;
  remoteConfig.setConfigSettings(RemoteConfigSettings(debugMode: true));
  remoteConfig.setDefaults(<String, dynamic> {
    'app_title': 'Baby'
  });

  return remoteConfig;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FireFlutter',
      home: MyHomePage(),
      // home: FutureBuilder<RemoteConfig>(
      //   future: setupRemoteConfig(),
      //   builder: (BuildContext context, AsyncSnapshot<RemoteConfig> snapshot) {
      //     return snapshot.hasData ? MyHomePage(remoteConfig: snapshot.data) : Container(
      //       child: Text('Remote Config has no data'),
      //     );
      //   },
      // )
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{

  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  String appTitle = 'Baby Names';


  void _showMessageDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mensagem FCM'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('$message')
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: (){
                Navigator.pop(context);
              },
            )
          ],
        );
      }
    );
  }

  @override
  void initState() {
    super.initState();

    setupRemoteConfig().then((remoteConfig) {
    print('RemoteConfig test');
    print(remoteConfig.getString('app_title'));
      // Using default duration to force fetching from remote server.
      remoteConfig.fetch(expiration: const Duration(seconds: 0));
      remoteConfig.activateFetched();
      setState(() {
        appTitle = remoteConfig.getString('app_title');
      });
    });

    _firebaseMessaging.configure(
    	onMessage: (Map<String, dynamic> message) async {
    		print('onMessage: $message');
    	},

    	onLaunch: (Map<String, dynamic> message) {
    		print('onLaunch: $message');
    	},

    	onResume: (Map<String, dynamic> message) {
    		print('onResume: $message');
    	}
    );

    _firebaseMessaging.getToken().then((token) {
      print(token);
    }).catchError((err){
      print('Falha ao recuperar token');
      print(err);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle),
      ),
      body: _buildBody(context)
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('baby').snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0)
        ),
        child: ListTile(
          title: Text(record.name),
          trailing: Text(record.votes.toString()),
          onTap: (){
            record.reference.updateData({
              'votes': record.votes+1
            });
          },
        ),
      ),
    );
  }
}