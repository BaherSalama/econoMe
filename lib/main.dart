import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:async';

getdatabase() async {
  return openDatabase(
    join(await getDatabasesPath(), 'doggie_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE node(id INTEGER PRIMARY KEY autoincrement, name TEXT, date TEXT,data TEXT,type INTEGER)',
      );
    },
    version: 1,
  );
}

final database = getdatabase();

class Node {
  final int? id;
  final String name;
  final String data;
  final String? date;
  final int type;

  const Node({
    this.id,
    this.date,
    required this.name,
    required this.data,
    required this.type,
  });

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'data': data,
      'date': DateTime.now().toString(),
      'type': type,
    };
  }

  @override
  String toString() {
    return 'Node{id: $id, name: $name, data: $data, date:$date, type:$type}';
  }
}

Future<void> insertNode(Node dog) async {
  final db = await database;

  await db.insert(
    'node',
    dog.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateNode(Node dog) async {
  // Get a reference to the database.
  final db = await database;

  await db.update(
    'node',
    dog.toMap(),
    // Ensure that the Dog has a matching id.
    where: 'id = ?',
    // Pass the node's id as a whereArg to prevent SQL injection.
    whereArgs: [dog.id],
  );
}

List<Node> filterAnimalsByType(List<Node> nodes, int type) {
  // Use the `where` method to filter the list
  return nodes.where((animal) => animal.type == type).toList();
}

Future<void> deleteNode(int id) async {
  // Get a reference to the database.
  final db = await database;

  // Remove the Dog from the database.
  await db.delete(
    'node',
    // Use a `where` clause to delete a specific dog.
    where: 'id = ?',
    // Pass the Dog's id as a whereArg to prevent SQL injection.
    whereArgs: [id],
  );
}

class Add extends StatefulWidget {
  final sad;
  const Add({super.key, this.sad = 0});
  @override
  State<Add> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<Add> {
  final name = TextEditingController();
  final data = TextEditingController();
  final type = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    data.dispose();
    type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text("Edit"),
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
            )),
        body: Column(
          children: [
            TextField(
              controller: name,
            ),
            TextField(
              controller: data,
            ),
            TextField(
              controller: type,
            ),
            TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.focused)) return Colors.red;
                  return null; // Defer to the widget's default.
                }),
              ),
              onPressed: () {
                insertNode(
                    Node(name: name.text, data: data.text, type: widget.sad));
                Navigator.pop(context);
              },
              child: Text('TextButton'),
            )
          ],
        ));
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});
  @override
  State<MyWidget> createState() => Main();
}

Future main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class Edit extends StatelessWidget {
  const Edit({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Center(
              child: Text("Add"),
            ),
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
            )),
        body: Column(
          children: [
            const Spacer(),
            Container(
                // margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const DropdownMenuItem(
                      child: Text("sad"),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("sad"),
                    )
                  ],
                )),
          ],
        ));
  }
}

class Main extends State<MyWidget> {
  bool sad = false;
  void mad() {
    setState(() {
      sad = !sad;
    });
  }

  Future<List<Node>> nodes() async {
    // Get a reference to the database.
    final db = await database;

    final List<Map<String, Object?>> nodeMaps = await db.query('node');

    // Convert the list of each dog's fields into a list of `Dog` objects.
    return [
      for (final {
            'id': id as int,
            'name': name as String,
            'data': data as String,
            'date': date as String,
            'type': type as int,
          } in nodeMaps)
        Node(id: id, name: name, data: data, date: date, type: type),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PieCanvas(
        child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.portrait_rounded),
          onPressed: () => {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Mainsettings()),
            )
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => {},
          ),
        ],
        title: const Center(
          child: Text("sad"),
        ),
      ),
      body: TabBarView(
        children: [
          FutureBuilder<List<Node>>(
            future: nodes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final items = filterAnimalsByType(snapshot.data!, 0);
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return PieMenu(
                      actions: [
                        PieAction(
                          tooltip: const Text('Edit'),
                          onSelect: () => {},
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Todo'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 1)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Delete'),
                          onSelect: () => {deleteNode(item.id!), mad()},
                          child: const Icon(Icons.delete),
                        ),
                        PieAction(
                          tooltip: const Text('Doing'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 2)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Done'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 3)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                      ],
                      child: pic_4text(node: item),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              // Show a loading indicator while waiting
              return const Center(child: CircularProgressIndicator());
            },
          ),
          FutureBuilder<List<Node>>(
            future: nodes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final items = filterAnimalsByType(snapshot.data!, 1);
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return PieMenu(
                      actions: [
                        PieAction(
                          tooltip: const Text('Edit'),
                          onSelect: () => {},
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('backlog'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 0)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Delete'),
                          onSelect: () => {deleteNode(item.id!), mad()},
                          child: const Icon(Icons.delete),
                        ),
                        PieAction(
                          tooltip: const Text('Doing'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 2)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Done'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 3)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                      ],
                      child: pic_4text(node: item),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              // Show a loading indicator while waiting
              return const Center(child: CircularProgressIndicator());
            },
          ),
          FutureBuilder<List<Node>>(
            future: nodes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final items = filterAnimalsByType(snapshot.data!, 2);
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return PieMenu(
                      actions: [
                        PieAction(
                          tooltip: const Text('Edit'),
                          onSelect: () => {},
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('backlog'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 0)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Delete'),
                          onSelect: () => {deleteNode(item.id!), mad()},
                          child: const Icon(Icons.delete),
                        ),
                        PieAction(
                          tooltip: const Text('Todo'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 1)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Done'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 3)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                      ],
                      child: pic_4text(node: item),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              // Show a loading indicator while waiting
              return const Center(child: CircularProgressIndicator());
            },
          ),
          FutureBuilder<List<Node>>(
            future: nodes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final items = filterAnimalsByType(snapshot.data!, 3);
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return PieMenu(
                      actions: [
                        PieAction(
                          tooltip: const Text('Edit'),
                          onSelect: () => {},
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Backlog'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 0)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Delete'),
                          onSelect: () => {deleteNode(item.id!), mad()},
                          child: const Icon(Icons.delete),
                        ),
                        PieAction(
                          tooltip: const Text('Todo'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 1)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                        PieAction(
                          tooltip: const Text('Doing'),
                          onSelect: () => {
                            updateNode(Node(
                                id: item.id,
                                name: item.name,
                                data: item.data,
                                type: 2)),
                            mad()
                          },
                          child: const Icon(Icons.info),
                        ),
                      ],
                      child: pic_4text(node: item),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              // Show a loading indicator while waiting
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            var index = DefaultTabController.of(context).index;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Add(sad: index)),
            );
          },
          shape: const CircleBorder(),
          // mini: false,
          // materialTapTargetSize: MaterialTapTargetSize.padded,
          // elevation: 2.0,
          child: const Icon(Icons.add_rounded)),
      bottomNavigationBar: const BottomAppBar(
        padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 5),
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        child: TabBar(
          // indicator: TopIndicator(color: Colors.white, height: 3.0),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: "Backlog",
              icon: Icon(Icons.backpack),
            ),
            Tab(
              text: "Todo",
              icon: Icon(Icons.access_time),
            ),
            Tab(
              text: "Doing",
              icon: Icon(Icons.adjust),
            ),
            Tab(
              text: "Done",
              icon: Icon(Icons.check_circle_outlined),
            ),
          ],
        ),
      ),
    ));
  }
}

class Mainsettings extends StatelessWidget {
  final Color color;
  const Mainsettings({super.key, this.color = Colors.deepPurple});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        )),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: const Text('Common'),
              tiles: <SettingsTile>[
                SettingsTile.navigation(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  value: const Text('English'),
                ),
                SettingsTile.switchTile(
                  onToggle: (value) {},
                  initialValue: true,
                  leading: const Icon(Icons.format_paint),
                  title: const Text('Enable custom theme'),
                ),
              ],
            ),
          ],
        ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        // Define the default brightness and colors.
        // colorScheme: ColorScheme.fromSeed(
        //   seedColor: Colors.purple,
        //   brightness: Brightness.dark,
        // ),

        // Define the default `TextTheme`. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
          // ···
        ),
      ),
      home: DefaultTabController(
          length: 4,
          child: MyWidget()), // Replace MyApp() with your main app widget
    );
  }
}

class icon_w_border extends StatelessWidget {
  final Color color;
  const icon_w_border({super.key, this.color = Colors.deepPurple});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 80,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      margin: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
          color: color.withAlpha(25), borderRadius: BorderRadius.circular(20)),
      child: Icon(Icons.mp, color: color, size: 40),
    );
  }
}

class pic_4text extends StatelessWidget {
  final Color color;
  final Node node;
  const pic_4text(
      {super.key,
      this.node = const Node(id: 1, date: "", data: "", name: "", type: 1),
      this.color = Colors.deepPurple});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(10),
        child: InkWell(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              // width: 165,
              // margin: EdgeInsets.all(10),
              height: 80,
              decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const icon_w_border(color: Colors.purple),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        node.name,
                        style: const TextStyle(fontSize: 25),
                      ),
                      const Spacer(),
                      Text(
                        node.data,
                      )
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateTime.now()
                            .difference(DateTime.parse(node.date!))
                            .toString(),
                        selectionColor: Colors.red,
                        style: const TextStyle(fontSize: 25, color: Colors.red),
                      ),
                      const Spacer(),
                      Text(
                        node.date!,
                      )
                    ],
                  )
                ],
              ),
            )));
  }

  Null get child => null;
}
