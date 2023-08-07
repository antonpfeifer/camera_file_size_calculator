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
      title: 'Camera Recording Time',
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
  late List<Profile> profiles;
  late List<Media> supportedMedia;
  Camera({
    required this.name,
    required this.id,
    required this.resolutions,
    required this.profiles,
    required this.supportedMedia,
  });
  Camera.fromJson(String identifier) {
    List<Map<String, String>>? rawProfiles = rawDatarates[identifier];
    final rawResolutions = rawFramerateData[identifier];
    name = identifier;
    id = identifier;
    profiles = rawProfiles!
        .map((e) => Profile(
            label: e.values.toList()[1],
            id: "${e.values.toList()[0]}${e.values.toList()[1]}",
            codecLabel: e.values.toList()[0]))
        .toList();
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
  Framerate? framerate;
  Media? media;
  Selection() {
    camera = null;
    profile = null;
    resolution = null;
    framerate = null;
    media = medias[0];
  }

  double? dataRate() {
    //MB/s
    String? string = rawDatarates[camera?.id]?.firstWhereOrNull((element) =>
        element["Profile"] == profile?.label &&
        element["Format"] == profile?.codecLabel)?[resolution?.id];
    return string == null ? null : double.parse(string) * 0.125;
  }

  double? recordingTimeSeconds() {
    if (media == null || dataRate() == null) {
      return null;
    } else {
      return media!.size / dataRate()!;
    }
  }

  Widget getRecordingTimeString() {
    TextStyle textStyle = TextStyle(fontSize: 15);
    if (camera == null ||
        profile == null ||
        resolution == null ||
        media == null) {
      return Text("Please input info first...");
    } else {
      return recordingTimeSeconds() != null
          ? Column(
              children: [
                Text(
                  formatedTime(time: recordingTimeSeconds()!.toInt()),
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
            )
          : Text(
              "Not available",
              textAlign: TextAlign.center,
              style: textStyle,
            );
    }
  }
}

String formatedTime({required int time}) {
  int sec = time % 60;
  int min = (time / 60).floor();
  String minute = min.toString().length <= 1 ? "0$min" : "$min";
  String second = sec.toString().length <= 1 ? "0$sec" : "$sec";
  return "$minute:$second";
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          title: Text("Sony Camera Recording Time"),
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
        ),
        body: ListView(
          children: [
            DropdownButtonHideUnderline(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    DropdownButton<Profile>(
                        value: _selection.profile,
                        hint: Text("Codec Profile"),
                        items: _selection.camera?.profiles
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
                        value: _selection.resolution,
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
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Column(
              children: [_selection.getRecordingTimeString()],
            ),
            SizedBox(
              height: 30,
            ),
            _selection.resolution != null
                ? Center(
                    child: Container(
                    height: 270,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 359,
                          height: 240,
                          child: Stack(
                            children: [
                              Center(
                                child: Center(
                                  child: Container(
                                    height: 240,
                                    width: 359,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.blue, width: 2),
                                        borderRadius: BorderRadius.circular(5)),
                                  ),
                                ),
                              ),
                              Center(
                                child: Center(
                                  child: Container(
                                      height:
                                          _selection.resolution!.height * 10,
                                      width: _selection.resolution!.width * 10,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
                                              width: 2),
                                          color: Color.fromARGB(78, 0, 0, 0))),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text("Sensor readout")
                      ],
                    ),
                  ))
                : SizedBox(),
          ],
        ));
  }
}
