/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 by David Schmidt
 * 1110325+david-schmidt@users.noreply.github.com
 *
 * Serial Transport notions derived from the jSyncManager project
 * http://jsyncmanager.sourceforge.net/
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

package org.adtpro.transport.audio;

import java.io.IOException;

import org.adtpro.utilities.Log;

public class BytesToWav
{

  public static byte[] encode(byte[] myFile, int length)
  {
    return encode(myFile, length, 300);
  }

  public static byte[] encode(byte[] myFile, int length, int leaderLength)
  {
    byte checksum = -1;
    Log.println(false,"BytesToWav.encode() entry, encoding "+length+" bytes.");
    java.io.ByteArrayOutputStream payload = new java.io.ByteArrayOutputStream(1024 * 1024);
    leaderTone(payload, SAMPLE_FREQ, leaderLength, 100);
    onePeriod(payload, 2200, SAMPLE_FREQ, 100, 0.0);
    checksum = encodeData(payload, myFile, length, checksum, SAMPLE_FREQ, 100);
    encodeByte(payload, checksum, SAMPLE_FREQ, 100, 0.0);
    onePeriod(payload, 200, SAMPLE_FREQ, 100, 0.0);
    silence(payload,100);
    java.io.ByteArrayOutputStream wholeFrigginThing = new java.io.ByteArrayOutputStream(44 + payload.size());
    try
    {
      wholeFrigginThing.write(payload.toByteArray());
    }
    catch (IOException e)
    {
      Log.printStackTrace(e);
    }
    return wholeFrigginThing.toByteArray();
  }

  /**
   * leaderTone - write a little bit of 770Hz tone
   * 
   * @param out
   * @param sampleFrequency
   * @param gain
   */
  static void leaderTone(java.io.ByteArrayOutputStream out, int sampleFrequency, int duration, int gain)
  {
    for (int i = 0; i < duration; i++)
    {
      onePeriod(out, 770, sampleFrequency, gain, 0.0);
    }
  }

  /**
   * silence - write some silence
   * 
   * @param out
   * @param sampleFrequency
   * @param gain
   */
  static void silence(java.io.ByteArrayOutputStream out, int gain)
  {
    for (int i = 0; i < 15000; i++)
    {
      out.write(0);
    }
  }

  static double onePeriod(java.io.ByteArrayOutputStream out, int frequency, int sampleFrequency, int gain, double inRemainder)
  {
    int numBytes = sampleFrequency / (2 * frequency);
    double remainder = inRemainder + (double)(((double)(sampleFrequency / (double)(2 * frequency))-numBytes)/20);
    byte value = 1;
    int i;
    for (i = 0; i < numBytes; i++)
    {
      out.write(value);
    }
    if (remainder > 1.0)
    {
      //Log.print(false,"BytesToWav.onePeriod() Adding one...");
      out.write(value);
    }
    value = -1;
    for (i = 0; i < numBytes; i++)
    {
      out.write(value);
    }
    if (remainder > 1.0)
    {
      //Log.println(false," Adding one.");
      out.write(value);
      remainder -= 1.0;
    }
    return remainder;
  }

  public static byte encodeData(java.io.ByteArrayOutputStream out, byte[] myFile, int length, byte checksum, int sampleFrequency, int gain)
  {
    int i;
    double remainder = 0.0;
    for (i = 0; i < length; i++)
    {
      checksum = (byte) (myFile[i] ^ checksum);
      remainder = encodeByte(out, myFile[i], sampleFrequency, gain, remainder);
      //Log.println(false,"BytesToWav.encodeData() remainder: "+remainder);
    }
    return checksum;
  }

  static double encodeByte(java.io.ByteArrayOutputStream out, byte data, int sampleFrequency, int gain, double inRemainder)
  {
    double remainder = inRemainder;
    for (int j = 0; j < 8; j++)
    {
      // Log.println(false,UnsignedByte.toString(data));
      if ((data & 0x00000080L) == 0x00000080L)
      {
        // It's a 1
        remainder = onePeriod(out, 1000, sampleFrequency, gain, remainder);
        //Log.print(false,"1");
      }
      else
      {
        // It's a 0
        remainder = onePeriod(out, 2000, sampleFrequency, gain, remainder);
        //Log.print(false,"0");
      }
      data = (byte) ((data << 1) & 0x000000FFL);
      //Log.println(false,"BytesToWav.encodeByte() remainder after bit: "+remainder);
    }
    //Log.println(false,"BytesToWav.encodeByte() returning remainder: "+remainder);
    return remainder;
  }

  public static final int SAMPLE_FREQ = 44100;
}