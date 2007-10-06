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

import org.adtpro.utilities.Log;

public class NibbleBufferEntry
{
  public NibbleBufferEntry(byte[] inBuffer)
  {
    this(inBuffer, NIBBLE_GAP, 0, 0);
  }

  public NibbleBufferEntry(byte[] inBuffer, int inType, int inStartIndex, int inLength)
  {
    buffer = inBuffer;
    type = inType;
    startIndex = inStartIndex;
    length = inLength;
  }

  public double weightedCompareWith(NibbleBufferEntry another)
  {
    int compareLength = (length < another.length) ? length : another.length;    // The smallest
    int calcLength = (length > another.length) ? length : another.length;       // The biggest
    double sum = 0.0;
    for (int i = 0; i < compareLength; i++)
    {
      if (buffer[i] == another.buffer[i])
        sum += 1.0;
      else if ((validDiskBytes[buffer[i]] == 0) ||
          (validDiskBytes[another.buffer[i]] == 0))
      {
        // At least one of the bytes is invalid; count partially.
        sum += 0.5;
      }
    }
    // If the lengths are unequal, add a "don't know" factor.
    sum += ((calcLength - compareLength) * 0.5);
    return sum / calcLength;
  }

  public SameContentsReturn sameContents(NibbleBufferEntry another)
  {
    SameContentsReturn rv = new SameContentsReturn();
    /*
     * Returns the chance this entry represents the same area as the other one,
     * and also assigns a weight to the result.
     * Both liklihood and weight run from 0.0 to 1.0.
     */
    if (another.length == 0)
      Log.println(true,"NibbleBufferEntry.sameContents() problem: another.length = 0!");
    if (type != another.type)
    {
      // An extremely important deviation!
      rv.liklihood = 0.0;
      rv.weight = 1.0;
    }
    switch (type)
    {
      case NIBBLE_GAP:
        // Gaps are equal if their lengths are the same
        rv.liklihood = this.length / another.length;
        if (rv.liklihood > 1.0)
          rv.liklihood = 1.0 / rv.liklihood;  // Oops, the other way around
        rv.weight = 0.2; // Much less important than a field
        break;
      case NIBBLE_FIELD:
        // Consider the lengths and the contents.  Any missing bytes in the shorter
        // of he two are considered to be at th eend, near the bitslip marks.
        rv.liklihood = weightedCompareWith(another);
        rv.weight = 1.0; // Pretty important
        break;
      case NIBBLE_BITSLIP:
        // These are always considered equal; their contents are unreliable,
        // so the weight is zero.
        rv.liklihood = 1.0;
        rv.weight = 0.0; // Not important at all
        break;
    }
    return rv;
  }

  static int validDiskBytes [] =
  {
      /*0x00*/0, /*0x01*/0, /*0x02*/0, /*0x03*/0, /*0x04*/0, /*0x05*/0, /*0x06*/0, /*0x07*/0,
      /*0x08*/0, /*0x09*/0, /*0x0A*/0, /*0x0B*/0, /*0x0C*/0, /*0x0D*/0, /*0x0E*/0, /*0x0F*/0,
      /*0x10*/0, /*0x11*/0, /*0x12*/0, /*0x13*/0, /*0x14*/0, /*0x15*/0, /*0x16*/0, /*0x17*/0,
      /*0x18*/0, /*0x19*/0, /*0x1A*/0, /*0x1B*/0, /*0x1C*/0, /*0x1D*/0, /*0x1E*/0, /*0x1F*/0,
      /*0x20*/0, /*0x21*/0, /*0x22*/0, /*0x23*/0, /*0x24*/0, /*0x25*/0, /*0x26*/0, /*0x27*/0,
      /*0x28*/0, /*0x29*/0, /*0x2A*/0, /*0x2B*/0, /*0x2C*/0, /*0x2D*/0, /*0x2E*/0, /*0x2F*/0,
      /*0x30*/0, /*0x31*/0, /*0x32*/0, /*0x33*/0, /*0x34*/0, /*0x35*/0, /*0x36*/0, /*0x37*/0,
      /*0x38*/0, /*0x39*/0, /*0x3A*/0, /*0x3B*/0, /*0x3C*/0, /*0x3D*/0, /*0x3E*/0, /*0x3F*/0,
      /*0x40*/0, /*0x41*/0, /*0x42*/0, /*0x43*/0, /*0x44*/0, /*0x45*/0, /*0x46*/0, /*0x47*/0,
      /*0x48*/0, /*0x49*/0, /*0x4A*/0, /*0x4B*/0, /*0x4C*/0, /*0x4D*/0, /*0x4E*/0, /*0x4F*/0,
      /*0x50*/0, /*0x51*/0, /*0x52*/0, /*0x53*/0, /*0x54*/0, /*0x55*/0, /*0x56*/0, /*0x57*/0,
      /*0x58*/0, /*0x59*/0, /*0x5A*/0, /*0x5B*/0, /*0x5C*/0, /*0x5D*/0, /*0x5E*/0, /*0x5F*/0,
      /*0x60*/0, /*0x61*/0, /*0x62*/0, /*0x63*/0, /*0x64*/0, /*0x65*/0, /*0x66*/0, /*0x67*/0,
      /*0x68*/0, /*0x69*/0, /*0x6A*/0, /*0x6B*/0, /*0x6C*/0, /*0x6D*/0, /*0x6E*/0, /*0x6F*/0,
      /*0x70*/0, /*0x71*/0, /*0x72*/0, /*0x73*/0, /*0x74*/0, /*0x75*/0, /*0x76*/0, /*0x77*/0,
      /*0x78*/0, /*0x79*/0, /*0x7A*/0, /*0x7B*/0, /*0x7C*/0, /*0x7D*/0, /*0x7E*/0, /*0x7F*/0,
      /*0x80*/0, /*0x81*/0, /*0x82*/0, /*0x83*/0, /*0x84*/0, /*0x85*/0, /*0x86*/0, /*0x87*/0,
      /*0x88*/0, /*0x89*/0, /*0x8A*/0, /*0x8B*/0, /*0x8C*/0, /*0x8D*/0, /*0x8E*/0, /*0x8F*/0,
      /*0x90*/0, /*0x91*/0, /*0x92*/0, /*0x93*/0, /*0x94*/0, /*0x95*/1, /*0x96*/1, /*0x97*/1,
      /*0x98*/0, /*0x99*/0, /*0x9A*/1, /*0x9B*/1, /*0x9C*/0, /*0x9D*/1, /*0x9E*/1, /*0x9F*/1,
      /*0xA0*/0, /*0xA1*/0, /*0xA2*/0, /*0xA3*/0, /*0xA4*/0, /*0xA5*/1, /*0xA6*/1, /*0xA7*/1,
      /*0xA8*/0, /*0xA9*/1, /*0xAA*/1, /*0xAB*/1, /*0xAC*/1, /*0xAD*/1, /*0xAE*/1, /*0xAF*/1,
      /*0xB0*/0, /*0xB1*/0, /*0xB2*/1, /*0xB3*/1, /*0xB4*/1, /*0xB5*/1, /*0xB6*/1, /*0xB7*/1,
      /*0xB8*/0, /*0xB9*/1, /*0xBA*/1, /*0xBB*/1, /*0xBC*/1, /*0xBD*/1, /*0xBE*/1, /*0xBF*/1,
      /*0xC0*/0, /*0xC1*/0, /*0xC2*/0, /*0xC3*/0, /*0xC4*/0, /*0xC5*/0, /*0xC6*/0, /*0xC7*/0,
    /*
     *  It appears that one game, namely "Alternate Reality, the Dungeon", relies on the
     *  nibble value 0xCC, which officially is not possible on a disk because 0xCC has two
     *  groups of adjacent zeros.  Well, there is no other option than to allow it I suppose.
     *  And let's hope no other unsupported values are possible.
     */
      /*0xC8*/0, /*0xC9*/0, /*0xCA*/1, /*0xCB*/1, /*0xCC*/1, /*0xCD*/1, /*0xCE*/1, /*0xCF*/1,
    // The official value for 0xCC
    ///*0xC8*/0, /*0xC9*/0, /*0xCA*/1, /*0xCB*/1, /*0xCC*/0, /*0xCD*/1, /*0xCE*/1, /*0xCF*/1,
      /*0xD0*/0, /*0xD1*/0, /*0xD2*/1, /*0xD3*/1, /*0xD4*/1, /*0xD5*/1, /*0xD6*/1, /*0xD7*/1,
      /*0xD8*/0, /*0xD9*/1, /*0xDA*/1, /*0xDB*/1, /*0xDC*/1, /*0xDD*/1, /*0xDE*/1, /*0xDF*/1,
      /*0xE0*/0, /*0xE1*/0, /*0xE2*/0, /*0xE3*/0, /*0xE4*/0, /*0xE5*/1, /*0xE6*/1, /*0xE7*/1,
      /*0xE8*/0, /*0xE9*/1, /*0xEA*/1, /*0xEB*/1, /*0xEC*/1, /*0xED*/1, /*0xEE*/1, /*0xEF*/1,
      /*0xF0*/0, /*0xF1*/0, /*0xF2*/1, /*0xF3*/1, /*0xF4*/1, /*0xF5*/1, /*0xF6*/1, /*0xF7*/1,
      /*0xF8*/0, /*0xF9*/1, /*0xFA*/1, /*0xFB*/1, /*0xFC*/1, /*0xFD*/1, /*0xFE*/1, /*0xFF*/1
  };

  /* cGapSequence contains all possible gap sequences. 
   * When we find one of these sequences in the
   * byte stream, we HAVE a gap.  See Beneath Apple DOS, 
   * page 3-9, for an explanation. It is assumed there are at least 5 gap
   * bytes in each gap. In the worst case, we only get to read 4 of them. */

  static int cGapSequence[][] =
  {
    {0x7F, 0x7F, 0x7F, 0x7F},
    {0x7E, 0x7F, 0x7F, 0x7F, 0x7F},
    {0x7C, 0x7F, 0x7F, 0x7F, 0x7F},
    {0x79, 0x7E, 0x7F, 0x7F, 0x7F},
    {0x73, 0x7C, 0x7F, 0x7F, 0x7F},
    {0x67, 0x79, 0x7E, 0x7F, 0x7F},
    {0x4F, 0x73, 0x7C, 0x7F, 0x7F},
    {0x1F, 0x67, 0x79, 0x7E, 0x7F},
    {0x00}                // Must be last
  };
  static int cGapSequence2[][] =
  {
    {0xFF, 0xFF, 0xFF, 0xFF},
    {0xFE, 0xFF, 0xFF, 0xFF, 0xFF},
    {0xFC, 0xFF, 0xFF, 0xFF, 0xFF},
    {0xF9, 0xFE, 0xFF, 0xFF, 0xFF},
    {0xF3, 0xFC, 0xFF, 0xFF, 0xFF},
    {0xE7, 0xF9, 0xFE, 0xFF, 0xFF},
    {0xCF, 0xF3, 0xFC, 0xFF, 0xFF},
    {0x9F, 0xE7, 0xF9, 0xFE, 0xFF},
    {0x00}                // Must be last
  };

  public class SameContentsReturn
  {
    double liklihood;
    double weight;
  }

  int type = NIBBLE_GAP;
  int startIndex = 0;
  int length = 0;
  byte[] buffer;

  public static final int NIBBLE_GAP = 0;
  public static final int NIBBLE_FIELD = 1;
  public static final int NIBBLE_BITSLIP = 2;
}