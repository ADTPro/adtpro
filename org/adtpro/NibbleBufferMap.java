package org.adtpro;

import java.util.Iterator;
import java.util.Vector;

import org.adtpro.NibbleBufferEntry.SameContentsReturn;
import org.adtpro.utilities.Log;

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
    int currentMode = MAP_FIELD_ENTRY_MODE;
    int numGapBytesObserved = 0;
    int currentAreaStart = 0; // The area we're analyzing now
    for (int i = 0; i < buffer.length; i++)
    {
      // Log.println(false,"Buffer byte ["+i+"]:"+buffer[i]);
      switch (currentMode)
      {
        case MAP_FIELD_ENTRY_MODE:
          if (buffer[i] == -1)
          {
            // A possible gap byte
            currentMode = MAP_TENTATIVE_GAP_MODE;
            numGapBytesObserved = 1;
          }
          break;
        case MAP_TENTATIVE_GAP_MODE:
          if (buffer[i] == -1)
          {
            // One more gap byte
            numGapBytesObserved++;
            if (numGapBytesObserved == MIN_GAP_LENGTH)
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
              currentMode = MAP_GAP_MODE;
              currentAreaStart = i - numGapBytesObserved + 1;
            }
          }
          else
          {
            // No gap after all
            currentMode = MAP_FIELD_ENTRY_MODE;
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
            currentMode = MAP_FIELD_ENTRY_MODE;
            currentAreaStart = i;
          }
          break;
        default:
          Log.println(true,"NibbleBufferMap internal error: look, this really shouldn't happen...");
          break;
      }
    } // For all bytes
  }

  int findFirstRepeatCandidate()
  {
    // Returns the index in mapEntries of the entry found, or -1 in the case of error.
    int rv = -1;
    NibbleBufferEntry entry;
    Iterator it = mapEntries.iterator();
    while (it.hasNext())
    {
      entry = (NibbleBufferEntry)it.next();
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
      // Log.println(false,"NibbleBufferMap.assessRepeatStartingAt() comparing "+i+" and "+otherIndex+".");
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
      //    Log.println(false,"NibbleBufferMap.determineTrackLength() looking at repeatCandidateIndex of "+repeatCandidateIndex+".");
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

  public static final int MAP_FIELD_ENTRY_MODE = 0;
  public static final int MAP_TENTATIVE_GAP_MODE = 1;
  public static final int MAP_GAP_MODE = 2;

  public static final int MIN_GAP_LENGTH = 3;
  public static final int BITSLIP_LENGTH = 6; // Number of unreliable bytes just before a gap
  public static final int NIBBLE_TRACK_LENGTH = 6656;
  public static final int MIN_TRACK_LENGTH = 4500; // TODO: Maybe...
}