import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Define a custom Form widget.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  // const HomeScreen({super.key});
  String value = "";
  String uname = "";

  @override
  Widget build(BuildContext context) {
    SnackBar mySnackBar = SnackBar(
      content: Row(
        children: const [
          Icon(
            Icons.info_outline,
            size: 30.0,
          ),
          SizedBox(width: 10.0),
          Text(
            "Enter a valid age!",
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
            ),
          ),
        ],
      ),
      elevation: 20.0,
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(
          color: Colors.red,
          width: 5.0,
        ),
      ),
      behavior: SnackBarBehavior.floating,
    );

    // Full screen width and height
    double devWidth = MediaQuery.of(context).size.width;
    double devHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hydration Check"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SizedBox(
            height: devHeight * 0.4,
            width: devWidth * 0.9,
            child: Card(
              color: const Color.fromRGBO(255, 255, 255, 0.65),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      style: const TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                      ),
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        filled: true,
                        contentPadding: EdgeInsets.all(15.0),
                        labelText: "Name",
                        hintText: "Please enter your name",
                      ),
                      onChanged: (text) {
                        // uname = text;
                        // log(uname);
                        setState(() {
                          uname = text;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    TextField(
                      style: const TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        filled: true,
                        contentPadding: EdgeInsets.all(15.0),
                        labelText: "Age",
                        hintText: "Please enter your age",
                      ),
                      onChanged: (text) {
                        // value = text;
                        setState(() {
                          value = text;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      ),
                      child: const Text(
                        "Predict",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      onPressed: () {
                        if (value == "" ||
                            int.parse(value) < 0 ||
                            int.parse(value) > 120) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(mySnackBar);
                        } else {
                          log("$uname $value");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SecondPage(
                                value: value,
                                uname: uname,
                              ),
                            ),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // return SecondPage(value: "25");
  }
}

class SecondPage extends StatefulWidget {
  const SecondPage({Key? key, required this.value, required this.uname})
      : super(key: key);

  final String value;
  final String uname;
  @override
  State<SecondPage> createState() => _SecondPage();
}

class _SecondPage extends State<SecondPage> {
  bool _isLoading = true;
  String? stat;
  double currUv = 0.0;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.requestPermission();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        } else if (permission == LocationPermission.deniedForever) {
          return Future.error("'Location permissions are permanently denied");
        } else {
          // return Future.("GPS Location service is granted");
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void fetchGsr(String age, String uname) async {
    // await Future.delayed(const Duration(seconds: 2));
    try {
      final location = await _determinePosition();
      log("LAT: ${location.latitude}, LONG: ${location.longitude}");
      final response = await http
          .get(
            Uri.http(
              "192.168.77.133:5000",
              "predict",
              {
                "age": age,
                "name": uname,
                "lat": location.latitude.toString(),
                "lng": location.longitude.toString()
              },
            ),
          )
          .timeout(const Duration(seconds: 20));
      log("${response.statusCode}");
      Map<String, dynamic> resTemp = json.decode(response.body);
      Map<String, String> temp = resTemp.map(((key, value) => MapEntry(key, value.toString())));
      log(temp.toString());

      setState(() {
        _isLoading = false;
        stat = temp["status"];
        currUv = double.parse(temp["uv"]!);
      });
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace.toString());
      setState(() {
        _isLoading = false;
        // stat = "Unexpected error";
        // stat = "Dehydrated";
        stat = "Server not responding";
      });
    }
  }

  @override
  void initState() {
    log(widget.uname);
    fetchGsr(widget.value, widget.uname);
    super.initState();
  }

  Widget loader(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(50),
        margin: const EdgeInsets.all(50),
        color: Colors.blue[100],
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget gsrStatus(BuildContext context) {
    final String value = widget.value;
    final String uname = widget.uname;
    // Full screen width and height
    double devWidth = MediaQuery.of(context).size.width;
    double devHeight = MediaQuery.of(context).size.height;
    int age = int.parse(value);
    int vitamind = 400, rTime = 30;
    if (age <= 1) {
      vitamind = 400;
    } else if (age <= 70) {
      vitamind = 600;
    } else {
      vitamind = 800;
    }

    if (currUv== 0) {
      rTime = -1;
    } else if (currUv<= 2) {
      rTime = 60;
    } else if (currUv<= 5) {
      rTime = 45;
    } else if (currUv<= 7) {
      rTime = 30;
    } else if (currUv<= 10) {
      rTime = 20;
    } else {
      rTime = 10;
    }

    AssetImage img = (stat != "Hydrated")
        ? const AssetImage('assets/images/dehydrated.jpg')
        : const AssetImage('assets/images/hydrated.jpg');

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: img, fit: BoxFit.cover),
      ),
      child: Center(
        child: SizedBox(
          height: devHeight * 0.35,
          width: devWidth * 0.9,
          child: Card(
            color: const Color.fromRGBO(255, 255, 255, 0.55),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Your Name: ",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        uname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Your age: ",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "You are ",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        stat!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Sufficient Vitamin-D intake: $vitamind IU",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    stat != "Hydrated"
                        ? (rTime == -1
                            ? "Please drink water 🚰! There is no UV radiation at this time! You can stay outdoors! 😊"
                            : "You are already dehydrated! Please stay indoors and drink water 🚰")
                        : (rTime == -1
                            ? "There is no UV radiation at this time! You can stay outdoors! 😊"
                            : "Time before you get Sunburned: $rTime mins"),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          stat != "Hydrated" ? Colors.redAccent : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Result"),
          backgroundColor: stat != "Hydrated" ? Colors.redAccent : Colors.green,
        ),
        body: !_isLoading ? gsrStatus(context) : loader(context));
  }
}
