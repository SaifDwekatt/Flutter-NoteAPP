import 'package:flutter/material.dart';
import 'package:note_app/screens/models/note.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'dart:convert';
import 'dart:math';
import 'editor_screen.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({Key? key}) : super(key: key);

  @override
  _NotesHomeScreenState createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  List<Note> notes = [];
  final Random _random = Random();
  List<TargetFocus> targets = [];
  GlobalKey keyCard = GlobalKey();
  GlobalKey keyFab = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _checkTutorialStatus();
  }

  _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedNotes = prefs.getString('notes');

    if (storedNotes != null) {
      List<dynamic> decodedNotes = jsonDecode(storedNotes);
      setState(() {
        notes = decodedNotes.map((note) => Note.fromMap(note)).toList();
      });
    }
  }

  _saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedNotes = jsonEncode(notes.map((e) => e.toMap()).toList());
    prefs.setString('notes', encodedNotes);
  }

  _addOrEditNote(Note note, [int? index]) {
    setState(() {
      if (index == null) {
        notes.add(note);
      } else {
        notes[index] = note;
      }
    });
    _saveNotes(); 
  }

  _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
    });
    _saveNotes();
  }

  Color _getRandomColor() {
    return Color.fromARGB(
      255,
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
    );
  }

  void _createNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          onSave: (String title, String content) {
            _addOrEditNote(Note(
              title: title,
              content: content,
            ));
          },
        ),
      ),
    );
  }

  void _editNote(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          note: notes[index], 
          onSave: (String title, String content) {
            _addOrEditNote(Note(
              title: title,
              content: content,
            ), index);
          },
        ),
      ),
    );
  }

  void _showNoteOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNote(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  _checkTutorialStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? tutorialShown = prefs.getBool('tutorial_shown');
    if (tutorialShown == null || !tutorialShown) {
      _showTutorial();
      prefs.setBool('tutorial_shown', true);
    }
  }

_showTutorial() {
  TutorialCoachMark(
    targets: _createTargets(), 
    colorShadow: Colors.black,
    textSkip: "SKIP",
    hideSkip: true,
    paddingFocus: 10,
    opacityShadow: 0.8,
  ).show(context: context); 
}



  List<TargetFocus> _createTargets() {
    return [
      TargetFocus(
        identify: "Target 1",
        keyTarget: keyCard,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Hold on a note to see options to delete or share.",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Target 2",
        keyTarget: keyFab,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Tap here to add a new note.",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: notes.isEmpty
          ? const Center(
              child: Text(
                'Create your first note!',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  key: index == 0 ? keyCard : null, 
                  onTap: () {
                    _editNote(index); 
                  },
                  onLongPress: () {
                    _showNoteOptions(index); 
                  },
                  child: Card(
                    color: _getRandomColor(),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 100, 
                      child: Center(
                        child: Text(
                          notes[index].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white, 
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        key: keyFab, 
        onPressed: _createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
