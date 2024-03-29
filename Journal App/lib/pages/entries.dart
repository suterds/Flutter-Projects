import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';

import 'package:project4_journal/pages/display_single_entry.dart';
import 'package:project4_journal/models/process_data.dart';


// Generates listview of all journal entries and loads 'Loading' page
// if async functions have not yet received data from database.
class JournalEntries extends StatefulWidget {

  @override
  JournalEntriesState createState() => new JournalEntriesState();
}

class JournalEntriesState extends State<JournalEntries> {
 
  var userJournal;
  final String apptitle = 'Journal Entries';
  
  // Retrieve journal entries from database
  void initState(){
    super.initState();
    loadJournal();
  }
  
  // Retreives journal entries from database
  Future loadJournal() async {
    // Open database file
    Database database = await openDatabase(
      'journal.sqlite3.db', version: 1, onCreate: (Database db, int version) async{
        var query = await processSQLData();
        await db.execute(query);
      });
    
    // Retrieve data from sql database
    List<Map> databaseEntries = await database.rawQuery('SELECT * FROM journal_entries');  

    // Create journal object to store database entries in a list
    final listEntries = databaseEntries.map((record){
      return Entries(
        title: record['title'],
        body: record['body'], 
        rating: record['rating'],
        dateTime: DateFormat('EEEE, d MMM, yyyy').format(DateTime.parse(record['date'])));
      }).toList();
    
    setState(() {
      userJournal = listEntries;
    });
  }

  @override 
  // Rebuild widgets when changes made/ new journal entry added
  void didUpdateWidget(JournalEntries oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadJournal();
  }
  
  // Determines device orientation and desired build
  Widget build(BuildContext context){    
    return LayoutBuilder(builder: layoutDecider,);
  }

  // Builds widgets per device orientation
  Widget layoutDecider (BuildContext context, BoxConstraints constraints) =>
  constraints.maxWidth < 500? verticalLayout(context) : horizontalLayout(context);

  // Determines whether to load 'loading' page or list of entries page
  Widget verticalLayout(BuildContext context)  {
    // If no data yet from database, load 'loading' page in the interim 
    return (userJournal == null ) ? loadPage(context) : loadList(context);   
  } 

  // Widget to display list of journal entries
  Widget loadList(BuildContext context){    
      return ListView.separated(
        itemCount: userJournal.length,
        separatorBuilder:  (BuildContext context, int index) => Divider(), 
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(userJournal[index].title),
            subtitle: Text(userJournal[index].dateTime.toString()),
            onTap: () {Navigator.push(
                context, MaterialPageRoute(builder: (context) {                
                  return DetailedEntries(newEntry: userJournal[index]);} 
                ),
            );},
          );
      });
  }

  // Widget to dispaly 'master mode' of journal entries
  Widget detailedVerticalLayout(BuildContext context){
  
  return ListView.separated(
      itemCount: userJournal.length,
      separatorBuilder:  (BuildContext context, int index) => Divider(), 
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
        title: Text(userJournal[index].title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),),
        subtitle: Text(userJournal[index].body + '\n' + userJournal[index].dateTime + '\n' + 'Rating: ' + userJournal[index].rating.toString(),)
        );
      });    
  } 

// Layout of widgets when phone orientation is horizontal
 Widget horizontalLayout(BuildContext context) {  
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: verticalLayout(context)),
        Expanded(child: detailedVerticalLayout(context))
      ]);  
  }

  // Widget for 'loading' page (when waiting for data back from 
  // database query)
  Widget loadPage(BuildContext context){    
      return Column(
        children: [
            Text('Loading', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            Center(child: CircularProgressIndicator(),)
        ],);    
  }
}
