/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 - 2023 by David Schmidt
 * 1110325+david-schmidt@users.noreply.github.com
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

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import javax.sound.sampled.*;

import org.adtpro.resources.Messages;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.UnsignedByte;

// Inner class to capture audio data
public class CaptureThread extends Thread
{
  // An arbitrarily-size temporary holding buffer
  final int BUFF_SIZE = 8192;
  byte buffer[] = new byte[BUFF_SIZE];

  ByteArrayOutputStream outputStream;

  AudioFormat audioFormat;

  TargetDataLine targetDataLine;

  boolean stopCapture = false;

  // Scan State phases
  public final int kPhaseUnknown = 0;
  public final int kPhaseScanFor770Start = 1;
  public final int kPhaseScanning770 = 2;
  public final int kPhaseScanForShort0 = 3;
  public final int kPhaseShort0B = 4;
  public final int kPhaseReadData = 5;
  public final int kPhaseEndReached = 6;

  // Scanning modes
  public final int kModeUnknown = 0;
  public final int kModeInitial0 = 1;
  public final int kModeInitial1 = 2;
  public final int kModeInTransition = 3;
  public final int kModeAtPeak = 4;
  public final int kModeRunning = 5;

  // Class-wide variables
  int     scanState_phase = kPhaseScanFor770Start;
  int     scanState_mode = kModeInitial0;
  boolean scanState_positive;           // rising or at +peak if true
  long    scanState_lastZeroIndex;      // in samples
  long    scanState_lastPeakStartIndex; // in samples
  float   scanState_lastPeakStartValue;
  float   scanState_prevSample;
  float   scanState_halfCycleWidth;     // in usec
  long    scanState_num770;             // #of consecutive 770Hz cycles
  long    scanState_dataStart;
  long    scanState_dataEnd;
  float   scanState_usecPerSample = 1000000.0f / 44100.0f;

  int bitVal;

  /* width of 1/2 cycle in 770Hz lead-in */
  public final float kLeadInHalfWidth = 650.0f;      // usec
  /* max error when detecting 770Hz lead-in, in usec */
  public final float kLeadInMaxError = 108.0f;       // usec (542 - 758)
  /* width of 1/2 cycle of "short 0" */
  public final float kShortZeroHalfWidth = 200.0f;   // usec
  /* max error when detection short 0 */
  public final float kShortZeroMaxError = 150.0f;    // usec (50 - 350)
  /* width of 1/2 cycle of '0' */
  public final float kZeroHalfWidth = 250.0f;        // usec
  /* max error when detecting '0' */
  public final float kZeroMaxError = 94.0f;          // usec
  /* width of 1/2 cycle of '1' */
  public final float kOneHalfWidth = 500.0f;         // usec
  /* max error when detecting '1' */
  public final float kOneMaxError = 94.0f;           // usec
  /* after this many 770Hz half-cycles, start looking for short 0 */
  public final long kLeadInHalfCycThreshold = 15;     // really, really short

  /* amplitude must change by this much before we switch out of "peak" mode */
  public final float kPeakThreshold = 0.2f;          // 10%
  /* amplitude must change by at least this much to stay in "transition" mode */
  public final float kTransMinDelta = 0.02f;         // 1%
  /* kTransMinDelta happens over this range */
  public final float kTransDeltaBase = 45.35f;       // usec (1 sample at 22.05KHz)


  
  int byteRegisterData = 0;

  int byteRegisterBits = 0;

  boolean isTraining = true;

  int transitionHysteresis = 3; // Was 18 in Marc's original implementation; seems to need to be (much) lower now.

  int transitionValue = 0;

  int transitionPeriod = 0;

  int transitionState = 0;

  int lastBit = -1;

  int _hardwareMixerIndex = 0;

  static int buffnum = 0;

  public CaptureThread(int hardwareMixerIndex)
  {
    _hardwareMixerIndex = hardwareMixerIndex;
  }

  public void run()
  {
    Log.println(true, "CaptureThread.run() entry with hardware mixer index "+_hardwareMixerIndex);
    try
    {
      // Get everything set up for capture
      audioFormat = getAudioFormat();
      DataLine.Info dataLineInfo = new DataLine.Info(TargetDataLine.class, audioFormat);
      if (_hardwareMixerIndex == 0)
      {
        targetDataLine = (TargetDataLine) AudioSystem.getLine(dataLineInfo);
        Log.println(true, "CaptureThread.run() using audio mixer "+Messages.getString("Gui.DefaultAudioMixer")+".");
      }
      else
      {
        Mixer.Info[] mixerInfo = AudioSystem.getMixerInfo();
        if (_hardwareMixerIndex < mixerInfo.length)
        {
          Mixer mixer = AudioSystem.getMixer(mixerInfo[_hardwareMixerIndex]);
          try
          {
            targetDataLine = (TargetDataLine) mixer.getLine(dataLineInfo);
            Log.println(true, "CaptureThread.run() using audio mixer "+mixerInfo[_hardwareMixerIndex].getName()+".");
          }
          catch (Exception e)
          {
            targetDataLine = (TargetDataLine) AudioSystem.getLine(dataLineInfo);
            Log.println(true, "CaptureThread.run() reverting to audio mixer "+Messages.getString("Gui.DefaultAudioMixer")+".");
          }
        }
      }
      targetDataLine.open(audioFormat);
      targetDataLine.start();
    }
    catch (Exception e)
    {
      Log.printStackTrace(e);
    }// end catch
    outputStream = new ByteArrayOutputStream();
    // Log.println(false,"Training(0)...");
    try
    {
      /*
       * Loop until stopCapture is set
       */
      while (!stopCapture)
      {
        // Read data from the internal
        // buffer of the data line.
        int cnt = targetDataLine.read(buffer, 0, buffer.length);
        if (cnt > 0)
        {
          interpretStream(buffer);
        }// end if
      }// end while
      outputStream.close();
    }
    catch (IOException e)
    {
      Log.printStackTrace(e);
    }// end catch
    targetDataLine.stop();
    targetDataLine.close();
    Log.println(true, "CaptureThread.run() exit.");
  }// end run

  void interpretStream(byte buffer[])
  {
    float sampleBuf[] = new float[BUFF_SIZE]; // kSampleChunkSize/bytesPerSample
    int chunkLen = buffer.length;
    int bitAcc = 1;
    // Set state to initial values
    scanState_phase = kPhaseScanFor770Start;
    scanState_mode = kModeInitial0;

    // System.out.println("Buffering...");

    // ConvertSamplesToReal: *sampleBuf++ = (*buf - 128) / 128.0f;
    for (int i = 0; i < chunkLen; i++)
    {
      sampleBuf[i] = (float) (UnsignedByte.intValue(buffer[i]) - 128) / 128.0f;
      // if (i < 2000) System.out.println("real sample "+i+": "+sampleBuf[i]+" byte value: 0x"+toString(buffer[i]));
    }
    for (int i = 0; i < chunkLen; i++)
    {
      if (processSample(sampleBuf[i], i))
      {
        // System.out.println("processSample: true");
        /* output a bit, shifting until bit 8 shows up */
        bitAcc = ((bitAcc << 1) | bitVal);
        if (bitAcc > 255 /* 0xff, but Java is funny about bytes */)
        {
          outputStream.write((byte)(bitAcc & 0xff));
          bitAcc = 1;
        }
      }
    }
    byte returnValue[] = outputStream.toByteArray();
    String a = "";
    for (int i = 0; i < returnValue.length; i++)
    {
      if ((returnValue[i] & 0xff) < 16) a = a + "0";
      a = a + Integer.toHexString(returnValue[i] & 0xff);
    }
    System.out.println("retrieveReceiveBuffer: " + a);

  }
  
  public boolean processSample(float sample, int sampleIndex)
  {
    long timeDelta;
    boolean crossedZero = false;
    boolean emitBit = false;

    /*
     * Analyze the mode, changing to a new one when appropriate.
     */
    switch (scanState_mode)
    {
      case kModeInitial0:
        // System.out.println("Switched to running mode");
        scanState_mode = kModeRunning;
        break;
      case kModeRunning:
        if (((scanState_prevSample < 0.0f) && (sample >= 0.0f)) ||
            ((scanState_prevSample >= 0.0f) && (sample < 0.0f)))
        {
          // System.out.println("crossed zero");
          crossedZero = true;
        }
        break;
    default:
        // assert(false);
        break;
    }

    /*
     * Deal with a zero crossing.
     *
     * We currently just grab the first point after we cross.  We should
     * be grabbing the closest point or interpolating across.
     */
    if (crossedZero)
    {
      float halfCycleUsec;
      int bias;
      if (Math.abs(scanState_prevSample) < Math.abs(sample))
        bias = -1;      // previous sample was closer to zero point
      else
        bias = 0;       // current sample is closer
      // System.out.println("Bias is "+bias);

      /* delta time for zero-to-zero (half cycle) */
      timeDelta = (sampleIndex + bias) - scanState_lastZeroIndex;
      // System.out.println("index delta = "+timeDelta);
      
      halfCycleUsec = timeDelta * scanState_usecPerSample;
      // System.out.println("halfCycleUsec = "+halfCycleUsec);

      emitBit = updatePhase(sampleIndex + bias, halfCycleUsec);
      // System.out.println("Emitted bit from updatePhase, sample index 0x"+Integer.toHexString(sampleIndex)+"? "+emitBit);

      scanState_lastZeroIndex = sampleIndex + bias;
      // System.out.println("scanState_lastZeroIndex = "+(sampleIndex + bias));
    }

    /* record this sample for the next go-round */
    scanState_prevSample = sample;

    return emitBit;
  }

  public boolean updatePhase(int sampleIndex, float halfCycleUsec)
  {
    float fullCycleUsec;
    boolean emitBit = false;
    
    if (scanState_halfCycleWidth != 0.0f)
      fullCycleUsec = halfCycleUsec + scanState_halfCycleWidth;
    else
      fullCycleUsec = 0.0f;   // only have first half

    switch (scanState_phase)
    {
      case kPhaseScanFor770Start:
        /* watch for a cycle of the appropriate length */
        if ((fullCycleUsec != 0.0f) &&
            (fullCycleUsec > kLeadInHalfWidth*2.0f - kLeadInMaxError*2.0f) &&
            (fullCycleUsec < kLeadInHalfWidth*2.0f + kLeadInMaxError*2.0f))
        {
            // System.out.println("  scanning 770 at 0x" + Integer.toHexString(sampleIndex));
            scanState_phase = kPhaseScanning770;
            scanState_num770 = 1;
        }
        break;
      case kPhaseScanning770:
        /* count up the 770Hz cycles */
        if ((fullCycleUsec != 0.0f) &&
            (fullCycleUsec > kLeadInHalfWidth*2.0f - kLeadInMaxError*2.0f) &&
            (fullCycleUsec < kLeadInHalfWidth*2.0f + kLeadInMaxError*2.0f))
        {
            scanState_num770++;
            // System.out.println("  times we're in 770 state: " + scanState_num770);
            if (scanState_num770 > kLeadInHalfCycThreshold/2)
            {
              /* looks like a solid tone, advance to next phase */
              scanState_phase = kPhaseScanForShort0;
              // System.out.println("  looking for short 0");
            }
        }
        else if (fullCycleUsec != 0.0f)
        {
          /* pattern lost, reset */
          if (scanState_num770 > 5)
          {
            // System.out.println("  lost 770 at 0x"+Integer.toHexString(sampleIndex)+" width="+fullCycleUsec+" (count="+scanState_num770+")");
          }
          scanState_phase = kPhaseScanFor770Start;
        }
        /* else we only have a half cycle, so do nothing */
        break;
      case kPhaseScanForShort0:
        /* found what looks like a 770Hz field, find the short 0 */
        if ((halfCycleUsec > kShortZeroHalfWidth - kShortZeroMaxError) &&
            (halfCycleUsec < kShortZeroHalfWidth + kShortZeroMaxError))
        {
          // System.out.println("  found short zero (half="+halfCycleUsec+") at 0x"+Integer.toHexString(sampleIndex)+" after "+scanState_num770+" 770s");
          scanState_phase = kPhaseShort0B;
          /* make sure we treat current sample as first half */
          scanState_halfCycleWidth = 0.0f;
        }
        else if ((fullCycleUsec != 0.0f) &&
                 (fullCycleUsec > kLeadInHalfWidth*2.0f - kLeadInMaxError*2.0f) &&
                 (fullCycleUsec < kLeadInHalfWidth*2.0f + kLeadInMaxError*2.0f))
        {
          /* found another 770Hz cycle */
          scanState_num770++;
        }
        else if (fullCycleUsec != 0.0f)
        {
          /* full cycle of the wrong size, we've lost it */
          // System.out.println("  Lost 770 at 0x"+Integer.toHexString(sampleIndex)+" width="+fullCycleUsec+" (count="+scanState_num770+")");
          scanState_phase = kPhaseScanFor770Start;
        }
        break;
      case kPhaseShort0B:
        /* pick up the second half of the start cycle */
        assert(fullCycleUsec != 0.0f);
        if ((fullCycleUsec > (kShortZeroHalfWidth + kZeroHalfWidth) - kZeroMaxError*2.0f) &&
            (fullCycleUsec < (kShortZeroHalfWidth + kZeroHalfWidth) + kZeroMaxError*2.0f))
        {
          /* as expected */
          // System.out.println("  Found 0B "+halfCycleUsec+" (total "+fullCycleUsec+"), advancing to 'read data' phase");
          scanState_dataStart = sampleIndex;
          scanState_phase = kPhaseReadData;
        }
        else
        {
          /* must be a false-positive at end of tone */
          // System.out.println("  Didn't find post-short-0 value (half="+scanState_halfCycleWidth+" + "+halfCycleUsec+")");
          scanState_phase = kPhaseScanFor770Start;
        }
        break;
      case kPhaseReadData:
        /* check width of full cycle; don't double error allowance */
        if (fullCycleUsec != 0.0f)
        {
          if ((fullCycleUsec > kZeroHalfWidth*2 - kZeroMaxError*2) &&
              (fullCycleUsec < kZeroHalfWidth*2 + kZeroMaxError*2))
          {
            bitVal = 0;
            emitBit = true;
          }
          else if ((fullCycleUsec > kOneHalfWidth*2 - kOneMaxError*2) &&
                   (fullCycleUsec < kOneHalfWidth*2 + kOneMaxError*2))
          {
            bitVal = 1;
            emitBit = true;
          }
          else
          {
            /* bad cycle, assume end reached */
            // System.out.println("  Bad full cycle time "+fullCycleUsec+" in data at 0x"+Integer.toHexString(sampleIndex)+", bailing");
            scanState_dataEnd = sampleIndex;
            scanState_phase = kPhaseEndReached;
          }
        }
        break;
    default:
        assert(false);
        break;
    }

    /* save the half-cycle stats */
    if (scanState_halfCycleWidth == 0.0f)
        scanState_halfCycleWidth = halfCycleUsec;
    else
        scanState_halfCycleWidth = 0.0f;

    return emitBit;
  }

  public int receiveBufferSize()
  {
    int mySize = 0;
    if (outputStream != null)
    {
      mySize = outputStream.size();
      // System.out.println("retrieveReceiveSize: " + mySize);
    }
    return mySize;
  }

  public byte[] retrieveReceiveBuffer()
  {
    byte[] returnValue = null;
    if (outputStream != null)
    {
      if (outputStream.size() > 0)
      {
        synchronized (outputStream)
        {
          returnValue = outputStream.toByteArray();
          String a = "";
          for (int i = 0; i < returnValue.length; i++)
          {
            if ((returnValue[i] & 0xff) < 16) a = a + "0";
            a = a + Integer.toHexString(returnValue[i] & 0xff);
          }
          // System.out.println("retrieveReceiveBuffer: " + a);
          outputStream.reset();
        }
      }
    }

    if (returnValue == null) returnValue = new byte[0];

    return returnValue;
  }

  public void pushBit(int bit)
  {
    byteRegisterData = ((byteRegisterData << 1) | bit) & 0xff;
    byteRegisterBits++;
    if (byteRegisterBits == 8)
    {
      outputStream.write(byteRegisterData);
      byteRegisterBits = 0;

      String a = "";
      if (byteRegisterData < 16) a = a + "0";
      a = Integer.toHexString(byteRegisterData);
      // System.out.println("pushBit: " + a);
    }
  }

  public void flushReceiveBuffer()
  {
    if (receiveBufferSize() > 0)
    //if (receiveBufferSize() > 128)  I'm confused... why would we not just flush if > 0?
    {
      // System.out.println("flushReceiveBuffer");
      synchronized (outputStream)
      {
        outputStream.reset();
      }
    }
  }

  public void requestStop()
  {
    stopCapture = true;
  }

  /*
   * This method creates and returns an AudioFormat object for a given set of
   * format parameters. The allowable parameter values are shown in comments
   * following the declarations.
   */
  public static AudioFormat getAudioFormat()
  {
    float sampleRate = 44100.0F; // 8000,11025,16000,22050,44100
    int sampleSizeInBits = 8; // 8,16
    int channels = 1; // 1,2
    boolean signed = true; // true,false
    boolean bigEndian = false; // true,false
    return new AudioFormat(sampleRate, sampleSizeInBits, channels, signed, bigEndian);
  }// end getAudioFormat
}
