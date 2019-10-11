import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geohash/geohash.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainScreenState();
  }
}

class MainScreenState extends State<MainScreen> {
  TextEditingController _nameController;

  TextEditingController _phoneController;

  List<Contact> _contacts;

  _dismissDialog() {
    Navigator.pop(context);
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _contacts = List<Contact>();
    _getContacts();
  }

  _getContacts() async {
    Firestore db = Firestore.instance;

    List<String> range = _getGeohashRange(46.874879, -96.767659, 10);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    db
        .collection('contacts')
        // .where("geohash", isGreaterThanOrEqualTo: range[0]) // Query based on location
        // .where("geohash",isLessThanOrEqualTo: range[1]) // Query based on location
        .where('creator_id', isEqualTo: prefs.getString('id'))
        .snapshots()
        .listen((data) {
      if (data != null) {
        List<Contact> contactList =
            data.documents.map((i) => Contact.fromJson(i)).toList();
        setState(() {
          _contacts = contactList;
        });
      }
    });
  }

  _getGeohashRange(
    double latitude,
    double longitude,
    double distance, // miles
  ) {
    double lat = 0.0144927536231884; // degrees latitude per mile
    double lon = 0.0181818181818182; // degrees longitude per mile

    double lowerLat = latitude - lat * distance;
    double lowerLon = longitude - lon * distance;

    double upperLat = latitude + lat * distance;
    double upperLon = longitude + lon * distance;

    String lower = Geohash.encode(lowerLat, lowerLon);
    String upper = Geohash.encode(upperLat, upperLon);

    return [lower, upper];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Main Screen',
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _contacts != null ? _contacts.length : 0,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(flex: 1, child: Text(_contacts[index].name)),
                      Text(_contacts[index].phoneNumber),
                    ],
                  ),
                ),
              );
            }),
        floatingActionButton: FloatingActionButton(
            key: UniqueKey(),
            child: Icon(Icons.add),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Add Contact'),
                      content: Container(
                        height: 120,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                    labelText: 'Enter contact name'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Enter contact name';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                    labelText: 'Enter phone number'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Enter phone number';
                                  }
                                  return null;
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                      actions: <Widget>[
                        FlatButton(
                            onPressed: () {
                              _dismissDialog();
                            },
                            child: Text('Close')),
                        OutlineButton(
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            if (_formKey.currentState.validate()) {
                              Firestore db = Firestore.instance;
                              String id = db
                                  .collection('contacts')
                                  .document()
                                  .documentID;
                              db.collection('contacts').document(id).setData({
                                'id': id,
                                'name': _nameController.text,
                                'phone_number': _phoneController.text,
                                'creator_id': prefs.getString('id'),
                                'createdAt': DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString()
                              });
                            }
                            _nameController.text = '';
                            _phoneController.text = '';
                            _dismissDialog();
                          },
                          child: Text('Submit!'),
                        )
                      ],
                    );
                  });
            }));
  }
}

class Contact {
  final String id;
  final String name;
  final String phoneNumber;

  Contact(this.id, this.name, this.phoneNumber);

  Contact.fromJson(DocumentSnapshot json)
      : id = json['id'],
        name = json['name'],
        phoneNumber = json['phone_number'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
      };
}
