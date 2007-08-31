package org.adtpro;

import org.adtpro.utilities.Log;

public class NibbleAnalysis
{
  public static NibbleTrack analyzeNibbleBuffer(byte[] rawNibbleBuffer)
  {
    Log.println(false,"NibbleAnalysis.analyzeNibbleBuffer() rawNibbleBuffer length: "+rawNibbleBuffer.length);
    NibbleTrack track = new NibbleTrack();
    NibbleBufferMap map = new NibbleBufferMap(rawNibbleBuffer);
    int trackLength = map.determineTrackLength();
    Log.println(false,"NibbleAnalysis.analyzeNibbleBuffer() length: "+trackLength);
    if (trackLength >= MIN_TRACK_LENGTH && trackLength <= NIBBLE_TRACK_LENGTH)
    {
      // Length is acceptable
      track.accuracy = map.accuracy;
      track.foundLength = trackLength;
      Log.println(false,"NibbleAnalysis.analyzeNibbleBuffer() Accuracy: "+track.accuracy+" Length: "+track.foundLength);
      composeNibbleTrack(track, map);
      /*
      Log.println(false, "Digested Nibble Buffer:");
      Log.println(false,"");
      int lineLen = 16;
      for (int i = 0; i < track.trackBuffer.length / lineLen; i++)
      {
        for (int j = 0; j < lineLen; j++)
        {
          Log.print(false,UnsignedByte.toString(track.trackBuffer[i*lineLen + j]));
          Log.print(false," ");
        }
        Log.println(false,"");
      }
      */
    }
    return track;
  }

  static void composeNibbleTrack(NibbleTrack track, NibbleBufferMap map)
  {
    /*
     * The task is to copy bytes from aBufAddr to aTrackAddr with a length
     * of aTrackLength.  That length is less than the current length
     * available from aTrackAddr, which must have been set in advance
     * to cNibbleTrackLength.  The catch is that we must fill up the
     * remainder of the aTrackAddr buffer with gap characters, 0xFF.
     * Because we know the first byte of aBufAddr was right behind a gap on
     * the diskette, it seems like we can add the gap after the last byte
     * copied.  Not so! When you insert a long gap (actually a type 1 gap)
     * between an address field and a data field the result is unusable.
     * The best solution is to add the gap bytes right before the longest
     * gap in the buffer; aMap can tell us where that is.  Because the buffer
     * has twice the entire track, we won't run out of bytes during the copy.
     */
    int currentIndex = 0;
    int startOfLongestGap = map.findLongestGapBefore(track.foundLength);
    int bytesToInsert = NIBBLE_TRACK_LENGTH - track.foundLength;
    //assert (lStartOfLongestGap > 0);
    //assert (lBytesToInsert >= 0);  // == 0 is only very theoretical, but still...
    // Now copy first part: from start of buffer to start of longest gap
    if (startOfLongestGap > 0)
    {
      // memcpy (aTrackAddr, aBufAddr, startOfLongestGap);
      // src : map.buffer[]
      // dest: track.trackBuffer[]
      // len: startOfLongestGap
      Log.println(false,"Copying first part for "+startOfLongestGap+" bytes.");
      for (int i = 0; i < startOfLongestGap; i++)
        track.trackBuffer[i] = map.buffer[i];
    }
    currentIndex = startOfLongestGap;    // Where to continue the copy
    // Now insert the right amount of gap characters.
    if (bytesToInsert > 0)
    {
      // memset (aTrackAddr + lCurrentIndex, 0xFF, lBytesToInsert);
      Log.println(false,"Inserting "+bytesToInsert+" bytes of gap.");
      for (int i = 0; i < bytesToInsert; i++)
        track.trackBuffer[currentIndex + i] = (byte)-1;
      currentIndex += bytesToInsert;
    }
    // Finally copy the remainder of the buffer
    // memcpy (aTrackAddr + lCurrentIndex, aBufAddr + lStartOfLongestGap, aTrackLength - lStartOfLongestGap);
    for (int i = 0; i < track.foundLength - startOfLongestGap; i++)
      track.trackBuffer[i+currentIndex] = map.buffer[i+startOfLongestGap];
    //System.arraycopy(track.trackBuffer,currentIndex,map.buffer,startOfLongestGap,track.foundLength - startOfLongestGap);
    Log.println(false,"Copying final buffer from "+currentIndex+" to "+(currentIndex+track.foundLength - startOfLongestGap)+".");
  }

  static final int MIN_TRACK_LENGTH = 4500; // TODO: Value OK ? Anyway, MUST be > 0
  static final int NIBBLE_TRACK_LENGTH = 6656;
}