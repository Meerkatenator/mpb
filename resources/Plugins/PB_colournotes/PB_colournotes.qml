//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013-2017 Nicolas Froment, Joachim Schmitz
//  Copyright (C) 2014 Jörn Eichler
//  Copyright (C) 2020 Kate Dudek
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import QtQuick 2.2
import MuseScore 3.0

/* This is a modification of colornotes.qml I've made This plugin colours notes in the selection depending on 
their pitch as per what I use in teaching Pipe Band Tenor Drumming.*/

MuseScore {
      version:  "4.0"
      description: qsTr("This plugin colours notes in the selection depending on their pitch as per my Pipe Band Tenor Drum convention")
      menuPath: "Plugins.Notes.PB Colour Notes"

      requiresScore: true

      Component.onCompleted : {
            if (mscoreMajorVersion >= 4) {
                  title = qsTr("PB_colournotes") ;
                  thumbnailName = "PB_colournotes.png";
                  categoryCode = "pipeband";
            }
      }

      property string black  : "#000000" //colour unassigned
	  property string red    : "#aa0000" //hiA
	  property string purple : "#69009e" //F#
	  property string green  : "#00aa00" //E
	  property string blue   : "#0055ff" //D
	  property string yellow : "#ffbf29" //C#
	  property string pink   : "#ff00ff" //loA
	  property string aqua   : "#6bf3ff" //loG
	  property string teal   : "#009c95" //hiG
	  property string orange : "#ff7d0c" //loB
	  property string peach  : "#ffaa7f" //hiB
	  
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
                  startStaff = cursor.staffIdx;
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
                                    for (var i = 0; i < graceChords.length; i++) {
                                          // iterate through all grace chords
                                          var graceNotes = graceChords[i].notes;
                                          for (var j = 0; j < graceNotes.length; j++)
                                                func(graceNotes[j]);
                                    }
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

	function pbColourNotes(note) {
            if (note.color == black)
                  switch (note.pitch) {
	           case 57:  note.color = peach; //hiB
                     break;
                   case 55:  note.color = red; //hiA
                     break;
                   case 53:  note.color = teal; //G
                     break;
 		   case 52:  note.color = purple; //F#
                     break;
		   case 50:  note.color = green; //E
                     break;
		   case 48:  note.color = blue; //D
                     break;
		   case 47:  note.color = yellow; //C#
                     break;
		   case 45:  note.color = orange; //loB
                     break;
		   case 43:  note.color = pink; //loA
                     break;
		   case 41:  note.color = aqua; //loG
                     break;
		   default: note.color == black; //unassigned
                     break;
	        }else{
			    note.color == black;
			}
			   
  
            for (var i = 0; i < note.dots.length; i++) {
                  if (note.dots[i]) {
                        if (note.dots[i].color == black)
                           switch (note.pitch) {
		              case 57:  note.dots[i].color = peach; //hiB
                                 break;
			      case 55:  note.dots[i].color = red; //hiA
                                 break;
		              case 53:  note.dots[i].color = teal; //G
                                 break;
			      case 52:  note.dots[i].color = purple; //F#
                                 break;
		              case 50:  note.dots[i].color = green; //E
                                 break;
			      case 48:  note.dots[i].color = blue; //D
                                 break;
			      case 47:  note.dots[i].color = yellow; //C#
                                 break;
			      case 45:  note.dots[i].color = orange; //loB
                                 break;
			      case 43:  note.dots[i].color = pink; //loA
                                 break;
			      case 41:  note.dots[i].color = aqua; //loG
                                 break;
			      default: note.dots[i].color == black; //unassigned
                                 break;
	                       }	   
                  } else {
				      note.dots[i].color == black;
				  }
            }
         }

onRun: {
            console.log("hello pbColourNotes");

            applyToNotesInSelection(pbColourNotes)

            quit();
         }
}
