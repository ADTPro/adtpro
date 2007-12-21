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

package org.adtpro.transport.audio;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import javax.sound.sampled.*;

import org.adtpro.resources.Messages;
import org.adtpro.utilities.Log;

// Inner class to capture audio data
public class CaptureThread extends Thread
{
  // An arbitrary-size temporary holding buffer
  byte buffer[] = new byte[8192];

  ByteArrayOutputStream outputStream;

  AudioFormat audioFormat;

  TargetDataLine targetDataLine;

  SourceDataLine sourceDataLine;

  boolean stopCapture = false;

  int byteRegisterData = 0;

  int byteRegisterBits = 0;

  boolean isTraining = true;

  int transitionHysteresis = 18;

  int transitionValue = 0;

  int transitionPeriod = 0;

  int transitionState = 0;

  int lastBit = -1;

  int _hardwareMixerIndex = 0;

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
          targetDataLine = (TargetDataLine) mixer.getLine(dataLineInfo);
          try
          {
            targetDataLine.open(audioFormat);
            targetDataLine.close();
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
    Log.println(true, "CaptureThread.run() exit.");
  }// end run

  void interpretStream(byte buffer[])
  {
    for (int i = 0; i < buffer.length; i++)
    {

      boolean isTransition;

      if ((transitionValue >= 0) && (buffer[i] >= transitionValue))
      {
        transitionValue = -transitionHysteresis;
        isTransition = true;
      }
      else
        if ((transitionValue < 0) && (buffer[i] <= transitionValue))
        {
          transitionValue = transitionHysteresis;
          isTransition = true;
        }
        else
          isTransition = false;
      transitionPeriod++;

      if (isTransition)
      {
        switch (transitionPeriod)
        {
          case 8: // 2200Hz
          case 9: // 2200Hz
          case 10: // 2000Hz
          case 11: // 2000Hz
          case 12: // 2000Hz
            if ((transitionState == 1) && (lastBit == 0))
            {
              if (isTraining)
              {
                // System.out.println("----");
                isTraining = false;
                break;
              }
              else
                pushBit(0);
              transitionState = 0;
            }
            else
              transitionState = 1;
            lastBit = 0;
            break;

          case 20: // 1000Hz
          case 21: // 1000Hz
          case 22: // 1000Hz
          case 23: // 1000Hz
            if (isTraining) break;
            if ((transitionState == 1) && (lastBit == 1))
            {
              pushBit(1);
              transitionState = 0;
            }
            else
              transitionState = 1;
            lastBit = 1;
            break;

          case 16: // 1200Hz
          case 17: // 1200Hz
          case 18: // 1200Hz
          case 19: // 1200Hz

          case 26: // 770Hz
          case 27: // 770Hz
          case 28: // 770Hz
          case 29: // 770Hz
          case 30: // 770Hz
          // if (!isTraining)
          // System.out.println("Training on");
            isTraining = true;
            transitionState = 0;
            byteRegisterBits = 0;
            break;
          default:
            // System.out.println("transitionPeriod:" + transitionPeriod);
            break;
        }

        transitionPeriod = 0;
      }
    }
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
    if (receiveBufferSize() > 128)
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
