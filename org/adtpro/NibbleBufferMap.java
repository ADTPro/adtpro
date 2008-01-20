/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 by David Schmidt
 * david__schmidt at users.sourceforge.net
 *
 * This program is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by the 
 * Free Software Foundation; either version 2 of the License, or (at your 
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
 * for more details.
 *
 * You should have received a copy of the GNU General Public License along 
 * with this program; if not, write to the Free Software Foundation, Inc., 
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

package org.adtpro;

import java.util.Iterator;
import java.util.Vector;

import org.adtpro.NibbleBufferEntry.SameContentsReturn;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.UnsignedByte;

/*      A NibbleBufferMap is the result of analyzing the different areas of
a nibble buffer, as received by the Apple II in the transfer process.
The entire buffer consists of consecutive areas, each with a different
type:
- A Gap area consists of FF characters, optionally preceded by characters
  read in the process of getting into sync. The latter IS important, 
  because sync can get lost even in the middle of a track, due to bit slip
  marks (unreliable characters). A gap must have a certain minimum length
  to qualify as such; the teoretical minimum is 5, but note that in some
  circumstances we get to read only 4 of them (Beneath Apple DOS, page 3-9).
  All gap bytes were supposed to be 10-bit self sync nibbles on the disk.
  Should something resembling gap bytes occur in the data portion of a disk, 
  there is no way to discern them from a gap. I don't consider this a serious
  problem; chance of this happening is very slim, and even if it happens 
  the analysis will be usable.
- A Field area is a sequence of bytes that are sure to belong to a piece
  of data. On a standard DOS disk this would typically be either an 
  address field or a data field. On a copy-protected disk it can be
  used for anything, so we just call it a "field". A Field always
  immediately follows a Gap, without intervening bytes.
- A Bitslip area are unreliable bytes, found between a Field and a
  Gap. They are the result of ending a write action, thereby destroying
  some bytes that were previously on the disk, and destroying the byte
  sync. These bytes are meaningless.

The serial transfer takes place in such a way that the buffer always 
starts with the first byte of a Field area. So effectively, an entire
buffer (as received) consists of a repitition of Field - Bitslip - Gap
areas. The last area in the buffer is of course probably truncated, and
therefore is NO part of the map. 
The buffer is more than twice as long as an "ideal" track, so dividing it
in such areas helps figure out the length of the track. After all,
it is to be expected that the Field areas (which contain relevant bytes)
repeat after tracklength bytes, and therefore appear twice in the buffer.

Construct a NibbleBufferMap by calling nibbleBufferMapWithBuffer. The
NSData object specified as buffer is not copied, but just retained.
So make sure to release the NibbleBufferMap object afterwards.

Call determineTrackLength to have the object guess the length of the 
track, based on the repitition of areas and values in the track.
The function returns -1 when it could not make sense of the track,
otherwise the track length returned is between cMinTrackLength and
cNibbleTrackLength.
*/

public class NibbleBufferMap
{
  NibbleBufferMap(byte[] inBuffer)
  {
    buffer = inBuffer;
    mapEntries = new Vector();
    buildMap();
  }

  void buildMap()
  {
    Log.println(false,"NibbleBufferMap.buildMap() inBuffer size: "+buffer.length);
    int currentAreaStart = 0; // The area we're analyzing now
    int numGapBytesObserved = 0;
    int tentativeGapStart = -1;
    for (int i = 0; i < buffer.length; i++)
    {
      // Log.println(false,"Buffer byte ["+i+"]:"+buffer[i]);
      switch (currentByteMode)
      {
        case MAP_FIELD_ENTRY_MODE:
          if (isFirstGapByte(buffer[i]))
          {
            // A possible gap byte
            currentByteMode = MAP_TENTATIVE_GAP_MODE; // Possibly a gap start
            tentativeGapStart = i; // Remember where we are
            numGapBytesObserved = 1;
          }
          break;
        case MAP_TENTATIVE_GAP_MODE:
          if (UnsignedByte.loByte(buffer[i]) == UnsignedByte.loByte(NibbleBufferEntry.cGapSequence[currentGapSequence][numGapBytesObserved]))
          {
            // One more gap byte
            numGapBytesObserved++;
            if (numGapBytesObserved == NibbleBufferEntry.cGapSequence[currentGapSequence].length)
            {
              /*
               * Yeah, it was a gap all the time.  That means we must
               * make two entries: first, a field entry and then a 
               * bitslip entry.  Calculate the length of the field
               * area first.
               */
              int bitslipStart;
              int areaLength = i - currentAreaStart - numGapBytesObserved - BITSLIP_LENGTH + 1;
              if (areaLength > 0)
              {
                NibbleBufferEntry entry = new NibbleBufferEntry(buffer,NibbleBufferEntry.NIBBLE_FIELD,currentAreaStart,areaLength);
                mapEntries.add(entry);
                bitslipStart = currentAreaStart + areaLength;
              }
              else
                bitslipStart = currentAreaStart;
              // Now create the bitslip entry.
              areaLength = i - bitslipStart - numGapBytesObserved + 1;
              if (areaLength > 0)
              {
                NibbleBufferEntry entry = new NibbleBufferEntry(buffer,NibbleBufferEntry.NIBBLE_BITSLIP,bitslipStart,areaLength);
                mapEntries.add(entry);
              }
              currentByteMode = MAP_GAP_MODE;
              currentAreaStart = i - numGapBytesObserved + 1;
            }
          }
          else
          {
            /*
             * No gap after all.  Resume field entry mode.
             * but also reset the index to the start of the
             * tentative gap + 1 because we have to re-examine
             * these bytes for gap start.
             */
            i = tentativeGapStart; // Will be incremented at the end of this iteration
            currentByteMode = MAP_FIELD_ENTRY_MODE;
            currentGapSequence = -1;
            numGapBytesObserved = 0;
          }
          break;
        case MAP_GAP_MODE:
          if (buffer[i] != -1)
          {
            // This is the first byte of the next field, so add a gap entry
            int areaLength = i - currentAreaStart;
            if (areaLength > 0)
            {
              NibbleBufferEntry entry = new NibbleBufferEntry(buffer,NibbleBufferEntry.NIBBLE_GAP,currentAreaStart,areaLength);
              mapEntries.add(entry);
            }
            currentByteMode = MAP_FIELD_ENTRY_MODE;
            currentAreaStart = i;
          }
          break;
        default:
          Log.println(true,"NibbleBufferMap internal error: look, this really shouldn't happen...");
          break;
      }
    } // For all bytes
    Log.println(false,"NibbleBufferMap.buildMap() exit; found "+mapEntries.size()+" map entries.");
  }

  boolean isFirstGapByte(byte aByte)
  {
    // This is to be called only when in cFieldEntryMode.
    boolean rv = false;
    int i = 0;
    byte lSequence;
    // Test our byte against the first byte of each potential gap sequence
    for (i = 0; (lSequence = UnsignedByte.loByte(NibbleBufferEntry.cGapSequence[i][0])) != 0x00; i++)
    {
      if (UnsignedByte.loByte(aByte) == lSequence)
      {
        currentGapSequence = i;
        rv = true;
        break; // end inner for loop
      } // end if byte matches
    } // end outer for loop
    return rv;
  }

  int findFirstRepeatCandidate()
  {
    // Returns the index in mapEntries of the entry found, or -1 in the case of error.
    int rv = 0;
    NibbleBufferEntry entry;
    Iterator it = mapEntries.iterator();
    while (it.hasNext())
    {
      entry = (NibbleBufferEntry)it.next();
      // Log.println(false, "NibbleBufferEntry type: "+entry.type);
      if ((entry.type == NibbleBufferEntry.NIBBLE_FIELD) && (entry.startIndex >= MIN_TRACK_LENGTH))
      {
        Log.println(false,"NibbleBufferMap.findFirstRepeatCandidate() found a candidate at "+rv+".");
        return rv;
      }
      rv++;
    }
    Log.println(false,"NibbleBufferMap.findFirstRepeatCandidate() returning -1.");
    return -1;
  }

  int findNextRepeatCandidate(int currentIndex)
  {
    // Returns the index in mapEntries of the next field entry after
    // currentIndex, or -1 if no such entry exists.
    int rv = -1; // Default - no candidate found
    for (int i = currentIndex + 1; i < mapEntries.size(); i++)
    {
      NibbleBufferEntry candidate = (NibbleBufferEntry)mapEntries.elementAt(i);
      if (candidate.startIndex > NIBBLE_TRACK_LENGTH)
      {
        rv = -1; // Track would become too long
        break;
      }
      if (candidate.type == NibbleBufferEntry.NIBBLE_FIELD)
      {
        rv = i;
        break;
      }
    }
    return rv;
  }

  double assessRepeatStartingAt(int candidateIndex)
  {
    /*
     * Plough through the areas from 0 to aCandidateIndex - 1 and compare with
     * the areas starting at aCandidateIndex. Don't just say whether there is a
     * match or not; instead return a number between 0 and 1 indicating the
     * probability of a match. It appears that some disks yield unreliable bytes, that
     * differ between reads of the same track. This can occur if the track contains
     * invalid bytes for example, or if a track is not initialized at all. The total
     * result of this function is the weighted average of the individual area compares.
     * A field area is more important than a gap, which in turn is more important than
     * a bitslip area. In fact, the latter area type doesn't count at all.
     */
    double rv = 0.5;
    double sum = 0.0;
    double num = 0.0;
    double result;
    int otherIndex;
    SameContentsReturn same;
    for (int i = 0; i < candidateIndex; i++)
    {
      otherIndex = i + candidateIndex;
      if (otherIndex >= mapEntries.size())
        break;
      NibbleBufferEntry first = (NibbleBufferEntry)mapEntries.elementAt(i);
      NibbleBufferEntry second = (NibbleBufferEntry)mapEntries.elementAt(otherIndex);
      //Log.println(false,"NibbleBufferMap.assessRepeatStartingAt() comparing "+i+" and "+otherIndex+".");
      if (second.length == 0)
      {
        Log.println(false,"NibbleBufferMap.assessRepeatStartingAt() found zero length second.");
      }
      same = first.sameContents(second);
      result = same.liklihood;
      num += same.weight;
      sum += (same.weight * result);
    }
    if (num > 0.0)
      rv = sum/num;
    return rv;
  }

  int determineTrackLength()
  {
    /*
     * Consider the sequence of field / bitslip / gap triplets that make up
     * more than MIN_TRACK_LENGTH, and see how well they repeat (value and length).
     * Function return -1 indicates a failure, and in that case accuracy is not
     * set. If function return is in the range MIN_TRACK_LENGTH to NIBBLE_TRACK_LENGTH,
     * the function succeeded, and accuracy is guaranteed to be > 0.0.  All other
     * return values also indicate failure.
     */
    int rv = -1;
    int repeatCandidateIndex;
    double bestMatchSoFar = 0.0;
    int bestRepeatIndexSoFar = 0;
    
    for (repeatCandidateIndex = this.findFirstRepeatCandidate();
         repeatCandidateIndex > 0;
         repeatCandidateIndex = this.findNextRepeatCandidate(repeatCandidateIndex))
    {
      //Log.println(false,"NibbleBufferMap.determineTrackLength() looking at repeatCandidateIndex of "+repeatCandidateIndex+".");
      double match = this.assessRepeatStartingAt(repeatCandidateIndex);
      if (match > bestMatchSoFar)
      {
        bestMatchSoFar = match;
        bestRepeatIndexSoFar = repeatCandidateIndex;
      }
    }
    if (bestMatchSoFar > 0.0)
    {
      // Apparently something was found
      NibbleBufferEntry candidate = (NibbleBufferEntry)mapEntries.elementAt(bestRepeatIndexSoFar);
      rv = candidate.startIndex;
    }
    this.accuracy = bestMatchSoFar;
    Log.println(false,"NibbleBufferMap.determineTrackLength() returning "+rv+" for track length.");
    return rv;
  }

  int findLongestGapBefore(int length)
  {
    /*
     * Determines the index in the buffer of the start of the longest gap that
     * lies entirely in the range buffer to buffer + aLength.  If multiple longest
     * gaps are equally long, the position of the first one is returned. If no gap
     * exists at all, the function returns 0 (this should not be possible, and a
     * gap can definitely not start at position 0).
     */
    int rv = 0;
    int bestSoFar = 0;
    NibbleBufferEntry entry;
    Iterator it = mapEntries.iterator();
    while (it.hasNext())
    {
      entry = (NibbleBufferEntry)it.next();
      if (entry.startIndex + entry.length <= length)
      {
        if ((entry.type == NibbleBufferEntry.NIBBLE_GAP) && (entry.length > bestSoFar))
        {
          bestSoFar = entry.length;
          rv = entry.startIndex;
        }
      }
    }
    return rv;
  }

  Vector mapEntries;
  public double accuracy = 0.0;
  byte[] buffer;
  int currentGapSequence = -1;

  int currentByteMode = MAP_FIELD_ENTRY_MODE;
  public static final int MAP_FIELD_ENTRY_MODE = 0;
  public static final int MAP_TENTATIVE_GAP_MODE = 1;
  public static final int MAP_GAP_MODE = 2;

  public static final int BITSLIP_LENGTH = 4; // Number of unreliable bytes just before a gap
  public static final int NIBBLE_TRACK_LENGTH = 6656;
  public static final int MIN_TRACK_LENGTH = 4500; // TODO: Maybe...
}