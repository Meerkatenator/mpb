//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013-2017 Nicolas Froment, Joachim Schmitz
//  Copyright (C) 2019 Bernard Greenberg
//  Copyright (C) 2020 Kate Dudek
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//
//  Version 3.1 BSG    3 Sept 2019 -- separation and rename "per mille" to "main note start"
//  Version 3.2 BSG   18 May  2020 -- use Qt quick dialog
//=============================================================================

import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

/* This is a modification of appoggiatura.qml I've made for improving playback of bagpipe music by making
the main notes play On The Beat.

Bagpipes have a continuous sound, and use ornamentation to create separation and emphasis between notes. 

The ornamentation generally occurs before the beat, and the main note generally starts on the beat, although
this isn't always the case. 

For the purposes of playback however, I am simplifying to maike the main note start on the beat and the 
grace note(s) as short as possible. This will make the melody come through properly in playback even
if the gracenotes are not played in the proper musical style.

This plugin hack combines the applytoallinselection function from colornotes.qml with the piano roll editor
content in appoggiatura.qml so that all selected notes (or whole piece if nothing is selected) can have 
identical settings applied throughout.

To use this, select a note or notes that has/have an appoggiatura. Invoke this plugin.  

The dividing per-mille will be updated to 
Main note start = 0
Separation = 0
Grace note length = 50

It adjust all selected "grace" and main notes and adjusts playback to play gracenotes before the beat. If nothing is selected, 
all  notes are adjusted.

By Default, appoggiaturas, in their musescore implementation, have the same "total" length as the note that they're modifying. 
However, their internally set length is so that the total number of appoggiaturas on a single note amount 
to half of the overall note length- the principal note therefore always has an ontime and length of 500, 
with the appoggiatura(s) having ontime and length such that they do not overlap and lengths sum to 500. To 
have them instead be before the beat, set the principal note length to 1000 and ontime to 0. From there, offset 
the appoggiatura ontimes to before the beat (-50). Start main note at 0 and adjust duration to fill whole main note. 
This gives the desired "before the beat" playback.

Principal note length 1000
Main note on time 0
gracenote length 50
grace note on time = 0 - gracenote length

"Separation" is the per mille between the end of the appoggiature and the start of the main note.
This is created as 0 by MuseScore and should be left that way for bagpipes.

This capability really ought be in the MS inspector, but this is a good work-around if that is too
controversial.

*/

MuseScore {
      version:  "4.0"
      description: qsTr("This plugin reduces the playback length of all appoggiature in the selection and makes main notes play on the beat")
      menuPath: "Plugins.Notes.PB_OTB"

      requiresScore: true

      Component.onCompleted : {
            if (mscoreMajorVersion >= 4) {
                  title = qsTr("PB_OTB") ;
                  thumbnailName = "PB_OTB.png";
                  categoryCode = "pipeband";
            }
      }

      property var the_note : null; 

      property var num_of_graces : null;    
      property var master_grace_length : 50;
      
 
      // Apply the given function to all notes in selection
      // or, if nothing is selected, in the entire score
      function applyToNotesInSelection(func) {
            var cursor = curScore.newCursor();
            cursor.rewind(1);
            var startStaff;
            var endStaff;
            var endTick;
            var fullScore = false;
            if (!cursor.segment) { // no selection
                  fullScore = true;
                  startStaff = 0; // start with 1st staff
                  endStaff = curScore.nstaves - 1; // and end with last
            } else {
                  startStaff = cursor .staffIdx;
                  cursor.rewind(2);
                  if (cursor.tick === 0) {
                        // this happens when the selection includes
                        // the last measure of the score.
                        // rewind(2) goes behind the last segment (where
                        // there's none) and sets tick=0
                        endTick = curScore.lastSegment.tick + 1;
                  } else {
                        endTick = cursor.tick;
                  }
                  endStaff = cursor.staffIdx;
            }
            console.log(startStaff + " - " + endStaff + " - " + endTick)
            for (var staff = startStaff; staff <= endStaff; staff++) {
                  for (var voice = 0; voice < 4; voice++) {
                        cursor.rewind(1); // sets voice to 0
                        cursor.voice = voice; //voice has to be set after goTo
                        cursor.staffIdx = staff;

                        if (fullScore)
                              cursor.rewind(0) // if no selection, beginning of score

                        while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                              if (cursor.element && cursor.element.type === Element.CHORD) {
                                    var graceChords = cursor.element.graceNotes;
                                    /*for (var i = 0; i < graceChords.length; i++) {
                                          // iterate through all grace chords
                                          var graceNotes = graceChords[i].notes;
                                          for (var j = 0; j < graceNotes.length; j++)
                                                func(graceNotes[j]);
                                    }*/
                                    var notes = cursor.element.notes;
                                    for (var k = 0; k < notes.length; k++) {
                                          var note = notes[k];
                                          func(note);
                                    }
                              }
                              cursor.next();
                        }
                  }
            }
      }

    function appoggiatura(note) {
//	    console.log("hello PBappoggiatura: appoggiatura func");
            var note_info = find_usable_note();
            if (note_info) {
                the_note = note_info.note;
                fixSettings(note);
            } else {
//                console.log("next")
            }
	}

    function fixSettings(note) {
			
	//main note
	var mpe0 = note.playEvents[0];
	var orig_ontime = mpe0.ontime;  // must be so if we are here.
	var new_main_on_time = 0;
	var main_off_time = mpe0.ontime + mpe0.len;   //doesn't change
	var new_main_len = main_off_time;
//	console.log("new on time", new_main_on_time, "new_main_len", new_main_len, "main_off_time", main_off_time);
			
	//grace
	var grace_chords = note.parent.graceNotes; //really
	var ngrace = grace_chords.length;  //chords, really
	var new_grace_len = master_grace_length;

       
        curScore.startCmd();
//        var current = 0;
//        current = ngrace; //note this is actually ngrace * new_grace_len, but len = 1
        for (var i = 0; i < ngrace; i++) {
            var chord = grace_chords[i];
//            console.log("i=", i);
            for (var j = 0; j < chord.notes.length; j++) {
//                console.log("chord.notes.length=", chord.notes.length);
//                console.log("j=", j);
                var gn0 = chord.notes[j];
                var pe00 = gn0.playEvents[0];
                var oldontime = pe00.ontime;
                pe00.len = new_grace_len;
                pe00.ontime = i*new_grace_len - ngrace*new_grace_len;
//                console.log("grace len", pe00.len, "grace ontime", pe00.ontime, "grace offtime", pe00.offtime);

                }
        }

        var notachord = note.parent;
        var chord_notes = notachord.notes;
        for (var k = 0; k < chord_notes.length; k++) {
            var cnote = chord_notes[k];
            var mpce0 = cnote.playEvents[0];
            mpce0.ontime = 0;
            mpce0.len = new_main_len;
//            console.log("main note len", mpce0.len, "main note ontime", mpce0.ontime, "main note offtime", mpce0.offtime);
        }
        curScore.endCmd()
//        console.log("Did it!");
        return true;        
    }       
    
    function find_usable_note() {
//        console.log("find useable note func");
        var selection = curScore.selection;
        var elements = selection.elements;
        if (elements.length > 0) {  // We have a selection list to work with...
//            console.log(elements.length, "selected elements"); // added ;
            for (var idx = 0; idx < elements.length; idx++) {
                var element = elements[idx]
//                console.log("element.type=" + element.type); // added ;
                if (element.type == Element.NOTE) {
                    var note = element;
                    var summa_gratiarum = sum_graces(note);
                    if (summa_gratiarum) {
                        var mnplayevs = note.playEvents;
                        var mpe0 = mnplayevs[0];
//                        dump_play_ev(mpe0);
			return {
			    note: note,
			    main_start: mpe0.ontime,
			    separation: mpe0.ontime - summa_gratiarum,
			}
                    }
                }
            }
        }
        return false;  // trigger dismay
    }
    
    function sum_graces(note){
        var chord = note.parent;
        var grace_chords = chord.graceNotes;  //it lies.
//        console.log("grace chords", grace_chords);    
        if (!grace_chords || grace_chords.length == 0) {
            return false;
        }

//        console.log("N grace chords", grace_chords.length);
        var summa = 0
        for (var i = 0; i < grace_chords.length; i++) {
            var grace_chord = grace_chords[i];;
//            console.log("grace chord#", i,  grace_chord);
            var grace_note = grace_chord.notes[0];
//            console.log("grace note", i, "[0]" , grace_note);
            var gpe0 = grace_note.playEvents[0];
//            dump_play_ev(gpe0);
            summa += gpe0.len;
        }
        num_of_graces = i;
//        console.log("summa", summa, "num_of_graces", num_of_graces);
        return summa;
    }
    
   function dump_play_ev(event) {
       console.log("DUMPING")
       console.log("on time", event.ontime, "len", event.len, "off time", event.ontime+event.len);
   }
	
onRun: {
            console.log("hello PB_OTB");
            curScore.createPlayEvents();  // Needed to get MS to realize the appogg 1st time
            applyToNotesInSelection(appoggiatura)
            console.log("Byebye, PB_OTB: we did it! Gracenote length = ", master_grace_length);
            quit();
         }
}
