import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:ch13_local_persistence/classes/database.dart';
import 'package:ch13_local_persistence/pages/edit_entry.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Database _database;
  Future<List<Journal>> _loadJournals() async {
    await DatabaseFileRoutines().readJournals().then((jounralsJson) {
      _database = databaseFromJson(jounralsJson);
      _database.journal
          .sort((comp1, comp2) => comp2.date.compareTo(comp1.date));
    });
    return _database.journal;
  }

  void _addOrEditJournal({bool add, int index, Journal journal}) async {
    JournalEdit _jounralEdit = JournalEdit(action: '', journal: journal);
    _jounralEdit = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEntry(
          add: add,
          index: index,
          journalEdit: _jounralEdit,
        ),
        fullscreenDialog: true,
      ),
    );
    switch (_jounralEdit.action) {
      case 'Save':
        if (add) {
          setState(() {
            _database.journal.add(_jounralEdit.journal);
          });
        } else {
          setState(() {
            _database.journal[index] = _jounralEdit.journal;
          });
        }
        DatabaseFileRoutines().writeJournals(databaseToJson(_database));
        break;
      case 'Cancel':
        break;
      default:
        break;
    }
  }

  Widget _buildListViewSeparated(AsyncSnapshot snapshot) {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          color: Colors.grey,
        );
      },
      itemCount: snapshot.data.length,
      itemBuilder: (BuildContext context, int index) {
        String _titleDate = DateFormat.yMMMd()
            .format(DateTime.parse(snapshot.data[index].date));
        String _subTitle =
            snapshot.data[index].mood + "\n" + snapshot.data[index].note;
        return Dismissible(
          key: Key(snapshot.data[index].id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(16.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            color: Colors.green,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.all(16.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: ListTile(
            leading: Column(
              children: [
                Text(
                  DateFormat.d()
                      .format(DateTime.parse(snapshot.data[index].date)),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 32.0,
                  ),
                ),
                Text(
                  DateFormat.E()
                      .format(DateTime.parse(snapshot.data[index].date)),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            title: Text(
              _titleDate,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(_subTitle),
            onTap: (){
              _addOrEditJournal(
                add: false,
                index: index,
                journal: snapshot.data[index],
              );
            },
          ),
          onDismissed: (direction) {
            setState(() {
              _database.journal.removeAt(index);
            });
            DatabaseFileRoutines().writeJournals(databaseToJson(_database));
            },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          initialData: [],
          future: _loadJournals(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return snapshot.hasData
                ? _buildListViewSeparated(snapshot): SizedBox(
              child: CircularProgressIndicator(),
              width: 60,
              height: 60,
            );

          }),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Add journal entry',
        onPressed: () {
          _addOrEditJournal(add: true, index: -1, journal: Journal());
        },
      ),
    );
  }
}
