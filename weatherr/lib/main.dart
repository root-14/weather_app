import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double temperature = 0;
  var minTempratureForecast = new List(7);
  var maxTempratureForecast = new List(7);
  int tempratureInt;
  String location = 'San Fransisco'; //default inputs gonna here
  int woeid = 2487956;
  String weather = 'heavyrain';
  String abbreviation = 'c'; //icon
  var abbreviationForecast = new List(7);
  String errorMsg = '';

  Position _currentPosition;
  String _currentAddress;

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  void initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(searchApiUrl + input);
      var result = json.decode(searchResult.body)[0];
      setState(() {
        location = result['title'];
        woeid = result['woeid'];
        errorMsg = '';
      });
    } catch (error) {
      setState(() {
        errorMsg = 'City cannot found.';
      });
    }
  }

  void fetchLocation() async {
    var locationResult = await http.get(locationApiUrl + woeid.toString());
    var result = json.decode((locationResult.body));
    var consolidatedWeather = result['consolidated_weather'];
    var data = consolidatedWeather[0];
    setState(() {
      temperature = data['the_temp'];
      //weather = data['weather_state_name'].replaceAll(' ', '').toLowerCase();
      abbreviation = data['weather_state_abbr']; //icon

      tempratureInt = temperature.round();

      print(
          'weather $weather temprature $temperature tempratureInt $tempratureInt');
    });
  }

  void fetchLocationDay() async {
    var today = new DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationResult = await http.get(locationApiUrl +
          woeid.toString() +
          '/' +
          new DateFormat('y/M/d')
              .format(today.add(new Duration(days: i+1)))
              .toString());
      var result = json.decode((locationResult.body));
      var data = result[0];
      print('result$result');

      setState(() {
        minTempratureForecast[i] = data['min_temp'].round();
        maxTempratureForecast[i] = data['max_temp'].round();
        abbreviation = data['weather_state_abbr'];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
      onTextFieldSubmitted(place.locality);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('imgs/$weather.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: temperature == null
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Scaffold(
                    resizeToAvoidBottomInset: false,
                    backgroundColor: Colors.transparent,
                    body: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          children: [
                            Center(
                              child: Image.network(
                                'https://www.metaweather.com/static/img/weather/png/$abbreviation.png', //icon
                                width: 100,
                              ),
                            ),
                            Center(
                                child: Text(
                              '$tempratureInt°C',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 60.0),
                            )),
                            Center(
                                child: Text(
                              '$location',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 40.0),
                            )),
                          ],
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              for (var i = 0; i < 7; i++)
                                forecastElement(
                                    i + 1,
                                    abbreviationForecast[i],
                                    minTempratureForecast[i],
                                    maxTempratureForecast[i]),
                            ],
                          ),
                        ),
                        Column(
                          //textfield barı hazırlık
                          children: [
                            Container(
                              width: 300,
                              child: TextField(
                                onSubmitted: (String input) {
                                  onTextFieldSubmitted(input);
                                },
                                showCursor: false,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 25.0),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  hintText: 'City name here',
                                  hintStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              errorMsg,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 15.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                    floatingActionButton: FloatingActionButton(
                      onPressed: () {
                        _getCurrentLocation();
                        print(_currentPosition);
                      },
                      //label: Text(''),
                      child: Icon(Icons.location_on),
                      mini: true,
                      backgroundColor: Colors.red,
                    ),
                  )),
      ),
    );
  }
}

Widget forecastElement(
    daysFromNow, abbreviation, minTemprature, maxTemprature) {
  var now = new DateTime.now();
  var oneDayFromNow = now.add(new Duration(days: daysFromNow));
  print('abbbr:$abbreviation min$minTemprature max$maxTemprature');

  return Padding(
    padding: const EdgeInsets.only(left: 16.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              new DateFormat.E().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              new DateFormat.MMMd().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            
            Text(
              'High $maxTemprature°C',
              style: TextStyle(color: Colors.white, fontSize: 10.0),
            ),
            Text(
              'Low $minTemprature°C',
              style: TextStyle(color: Colors.white, fontSize: 10.0),
            ),
            
          ],
        ),
      ),
    ),
  );
}
