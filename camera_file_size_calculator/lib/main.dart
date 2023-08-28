import 'package:camera_file_size_calculator/json.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sony CineAlta Data Rate Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

List<Camera> cameras = [
  Camera.fromJson("Sony Venice 2 8K"),
  Camera.fromJson("Sony Venice 2 6K")
];

List<Media> medias = [
  Media(label: "1 TB", size: 1000000, id: "1tb"),
  Media(label: "500 GB", size: 512000, id: "500gb")
];

class Camera {
  late String name;
  late String id;
  late List<Resolution> resolutions;
  late List<Codec> codecs;
  late List<Media> supportedMedia;
  Camera({
    required this.name,
    required this.id,
    required this.resolutions,
    required this.codecs,
    required this.supportedMedia,
  });
  Camera.fromJson(String identifier) {
    List<Map<String, String>>? rawProfiles = rawDatarates[identifier];
    final rawResolutions = rawFramerateData[identifier];
    final List<Profile> _profiles = rawProfiles!
        .map((e) => Profile(
            label: e.values.toList()[1],
            id: "${e.values.toList()[0]}${e.values.toList()[1]}",
            codecLabel: e.values.toList()[0]))
        .toList();
    List<Codec> _dublicatedCodecs = _profiles
        .map((e) => Codec(
            id: e.codecLabel,
            label: e.codecLabel,
            profiles: _profiles
                .where((element) => element.codecLabel == e.codecLabel)
                .toList()))
        .toList();
    List<Codec> _codecs = [];
    Profile? pp;
    for (Profile p in _profiles) {
      if (_codecs.where((element) => element.label == p.codecLabel).isEmpty) {
        _codecs.add(Codec(
            label: p.codecLabel,
            profiles: _profiles
                .where((element) => element.codecLabel == p.codecLabel)
                .toList(),
            id: p.codecLabel));
      }
    }

    name = identifier;
    id = identifier;
    codecs = _codecs.toList();
    resolutions = rawResolutions!
        .map((e) => Resolution(
            framerates: frameratesFromString(e["project frame rates"]!),
            label: "${e["resolution"]} ${e["aspect ratio"]}",
            resolution: e["resolution"]!,
            width:
                double.parse(e["size"]!.substring(0, e["size"]!.indexOf("X"))),
            height:
                double.parse(e["size"]!.substring(e["size"]!.indexOf("X") + 1)),
            aspectRatio: e["aspect ratio"]!,
            id: "${e["resolution"]}${e["aspect ratio"]}"))
        .toList();
  }

  List<Framerate> frameratesFromString(String string) {
    List<String> currentCharacters = [];
    List<Framerate> framerates = [];
    for (String e in string.characters) {
      if (e != " " && e != ",") {
        currentCharacters.add(e);
      }
      if (currentCharacters.length == 2) {
        framerates.add(Framerate(
            int.parse("${currentCharacters[0]}${currentCharacters[1]}")));
        currentCharacters = [];
      }
    }
    return framerates;
  }
}

class Resolution {
  late String resolution;
  late String label;
  late double height;
  late double width;
  late String aspectRatio;
  late List<Framerate> framerates;

  late String id;
  Resolution(
      {required this.label,
      required this.resolution,
      required this.height,
      required this.width,
      required this.aspectRatio,
      required this.framerates,
      required this.id});

  //String get aspectRatio =>
}

class Codec {
  late String label;
  late List<Profile> profiles;
  late String id;
  Codec({required this.label, required this.profiles, required this.id});
}

class Profile {
  late String label;
  late String codecLabel;
  late String id;
  Profile({required this.label, required this.id, required this.codecLabel});
}

class Media {
  final String label;
  final int size;
  final String id;
  Media({required this.label, required this.size, required this.id});
}

class Framerate {
  final int fps;
  Framerate(this.fps);

  String get label => "${fps} FPS";
}

class Selection {
  Camera? camera;
  Profile? profile;
  Resolution? resolution;
  Codec? codec;
  Framerate? framerate;
  Media? media;
  Selection() {
    camera = null;
    codec = null;
    profile = null;
    resolution = null;
    framerate = null;
    media = medias[0];
  }

  double? get dataRate {
    //MB/s
    String? string = rawDatarates[camera?.id]?.firstWhereOrNull((element) =>
        element["Profile"] == profile?.label &&
        element["Format"] == profile?.codecLabel)?[resolution?.id];
    return (camera == null || profile == null || resolution == null)
        ? null
        : string == null
            ? -1
            : double.parse(string) * 0.125;
  }

  String get dataRateGbh {
    return dataRate != null
        ? dataRate == -1
            ? "not supported"
            : ((dataRate! / 1000) * 60).toStringAsFixed(1)
        : "-";
  }

  String get dataRateMbits {
    return dataRate != null
        ? dataRate == -1
            ? "not supported"
            : (dataRate! * 8).toStringAsFixed(0)
        : "-";
  }

  String get frameRateString {
    return resolution != null
        ? "${resolution!.framerates.first.label} - ${resolution!.framerates.last.label}"
        : "-";
  }

  String get recordingTime {
    if (media == null || dataRate == null) {
      return "-";
    } else if (dataRate == -1) {
      return "not supported";
    } else {
      return formatedTime(time: (media!.size / dataRate!).toInt());
    }
  }

  String get imageSize {
    return resolution != null
        ? "${resolution!.width} x ${resolution!.height} mm"
        : "unavailable";
  }

  String get cropFactor {
    return resolution != null
        ? "x${((1 - ((resolution!.width * resolution!.height) / (35.9 * 24.0))) + 1).toStringAsFixed(1)}"
        : "unavailable";
  }

  Widget getRecordingTimeString() {
    TextStyle textStyle = TextStyle(fontSize: 15);
    if (camera == null ||
        profile == null ||
        resolution == null ||
        media == null) {
      return Text("Please input info first...");
    } else {
      return Column(
        children: [
          Text(
            recordingTime,
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic),
          ),
          Text(
            "minutes of recording",
            textAlign: TextAlign.center,
            style: textStyle,
          )
        ],
      );
    }
  }
}

class DataListTile extends StatelessWidget {
  final String leading;
  final String trailing;
  const DataListTile(
      {required this.leading, required this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leading),
            Text(
              trailing,
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}

String formatedTime({required int time}) {
  int sec = time % 60;
  int h = (time / 3600).floor();
  int min = ((time / 60) - (h * 60)).floor();

  String hour = h.toString().length <= 1 ? "0$h" : "$h";
  String minute = (min.toString().length) <= 1 ? "0$min" : "$min";
  String second = sec.toString().length <= 1 ? "0$sec" : "$sec";
  return "$hour:$minute:$second";
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Selection _selection = Selection();

  @override
  Widget build(BuildContext context) {
    List<Widget> settings = [
                                DropdownButton<Camera>(
                                    value: _selection.camera,
                                    hint: Text("Camera"),
                                    items: cameras
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e.name),
                                            ))
                                        .toList(),
                                    onChanged: (e) => setState(() {
                                          _selection.camera = e;
                                        })),
                                DropdownButton<Codec>(
                                    value: _selection.camera?.codecs
                                                .contains(_selection.codec) ??
                                            false
                                        ? _selection.codec
                                        : null,
                                    hint: Text("Codec"),
                                    items: _selection.camera?.codecs
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e.label),
                                            ))
                                        .toList(),
                                    onChanged: (e) => setState(() {
                                          _selection.codec = e;
                                        })),
                                DropdownButton<Profile>(
                                    value: _selection.codec?.profiles
                                                .contains(_selection.profile) ??
                                            false
                                        ? _selection.profile
                                        : null,
                                    hint: Text("Codec Profile"),
                                    items: _selection.codec?.profiles
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e.label),
                                            ))
                                        .toList(),
                                    onChanged: (e) => setState(() {
                                          _selection.profile = e;
                                        })),
                                DropdownButton<Resolution>(
                                    hint: Text("Imager Mode"),
                                    value: _selection.camera?.resolutions
                                                .contains(
                                                    _selection.resolution) ??
                                            false
                                        ? _selection.resolution
                                        : null,
                                    items: _selection.camera?.resolutions
                                        .map((e) => DropdownMenuItem(
                                            value: e, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) => setState(() {
                                          _selection.resolution = e;
                                        })),
                                DropdownButton<Media>(
                                    hint: Text("Media Size"),
                                    value: _selection.media,
                                    items: medias
                                        .map((e) => DropdownMenuItem(
                                            value: e, child: Text(e.label)))
                                        .toList(),
                                    onChanged: (e) => setState(() {
                                          _selection.media = e;
                                        })),
                              ];
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Sony CineAlta Data Rate Calculator",
            style: TextStyle(color: Colors.white),
          ),
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Colors.black,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
        ),
        body: ListView(
          children: [
            Center(
              child: Container(
                width: 400,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: Column(
                      children: [
                        Text(
                          "Camera Settings",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: DropdownButtonHideUnderline(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: settings.map((e) => Row(children: [e.],)).toList()
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            /*Column(
              children: [_selection.getRecordingTimeString()],
            ),*/
            Center(
              child: Container(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Results",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    DataListTile(
                        leading: "Recording Time (hh:mm:ss)",
                        trailing: _selection.recordingTime),
                    DataListTile(
                        leading: "Data Rate (GB/h)",
                        trailing: (_selection.dataRateGbh)),
                    DataListTile(
                        leading: "Data Rate (Mbit/s)",
                        trailing: (_selection.dataRateMbits)),
                    DataListTile(
                        leading: "Frame Rates",
                        trailing: _selection.frameRateString)
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            _selection.resolution != null
                ? Center(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Format Preview",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 7,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 400,
                            height: 267,
                            child: Stack(
                              children: [
                                Center(
                                  child: Center(
                                    child: Container(
                                      height: 267,
                                      width: 400,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.blueGrey, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Center(
                                    child: Container(
                                        height: _selection.resolution!.height *
                                            10 *
                                            1.114206128,
                                        width: _selection.resolution!.width *
                                            10 *
                                            1.114206128,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            border: Border.all(
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0),
                                                width: 2),
                                            color:
                                                Color.fromARGB(78, 0, 0, 0))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      DataListTile(
                          leading: "Image Area Size",
                          trailing: _selection.imageSize),
                      DataListTile(
                          leading: "Crop Factor",
                          trailing: _selection.cropFactor)
                    ],
                  ))
                : SizedBox(),
                SizedBox(height: 10,),
                Text("Note: Current firmware (V2.10) required to access all features")
          ],
        ));
  }
}
