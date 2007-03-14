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

import java.util.GregorianCalendar;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.SourceDataLine;

import org.adtpro.gui.Gui;
import org.adtpro.resources.Messages;
import org.adtpro.utilities.Log;

public class PlaybackThread extends Thread
{
  byte[] _audioData;

  Gui _parent = null;

  boolean _shouldRun = true;

  public PlaybackThread(byte[] audioData, Gui parent)
  {
    _audioData = audioData;
    _parent = parent;
  }

  public PlaybackThread(byte[] audioData)
  {
    _audioData = audioData;
  }

  public void run()
  {
    play();
  }

  public void requestStop()
  {
    _shouldRun = false;
  }

  public void play()
  {
    GregorianCalendar startTime, endTime;
    float diffMillis = 0;
    Log.println(false, "PlaybackThread.play() entry.");
    startTime = new GregorianCalendar();
    /*
     * From the AudioInputStream, i.e. from the sound file, we fetch information
     * about the format of the audio data. These information include the
     * sampling frequency, the number of channels and the size of the samples.
     * These information are needed to ask Java Sound for a suitable output line
     * for this audio file.
     */
    AudioFormat audioFormat = new AudioFormat(44100, 8, 1, false, true);

    /*
     * Asking for a line is a rather tricky thing. We have to construct an Info
     * object that specifies the desired properties for the line. First, we have
     * to say which kind of line we want. The possibilities are: SourceDataLine
     * (for playback), Clip (for repeated playback) and TargetDataLine (for
     * recording). Here, we want to do normal playback, so we ask for a
     * SourceDataLine. Then, we have to pass an AudioFormat object, so that the
     * Line knows which format the data passed to it will have. Furthermore, we
     * can give Java Sound a hint about how big the internal buffer for the line
     * should be. This isn't used here, signaling that we don't care about the
     * exact size. Java Sound will use some default value for the buffer size.
     */
    SourceDataLine line = null;
    SourceDataLine.Info info = new DataLine.Info(SourceDataLine.class, audioFormat);
    try
    {
      line = (SourceDataLine) AudioSystem.getLine(info);
      /*
       * The line is there, but it is not yet ready to receive audio data. We
       * have to open the line.
       */
      line.open(audioFormat);
      line.start();
    }
    catch (Exception e)
    {
      Log.printStackTrace(e);
    }
    /*
     * Ok, finally the line is prepared. Now comes the real job: we have to
     * write data to the line. We do this in a loop. First, we read data from
     * the AudioInputStream to a buffer. Then, we write from this buffer to the
     * Line. This is done until the end of the file is reached, which is
     * detected by a return value of -1 from the read method of the
     * AudioInputStream.
     */
    // line.open(audioFormat, _audioData);//, 0, _audioData.length);
    // open(AudioFormat format, byte[] data, int offset, int bufferSize)
    Log.println(false, "PlaybackThread.play() payload size: " + _audioData.length);
    if (_parent != null) _parent.setProgressMaximum(_audioData.length);
    int i, nBytesWritten = 0;
    int chunk = _audioData.length / 100;
    //for (i = 0; i < 100; i++)
    {
      if (_shouldRun)
      {
        nBytesWritten += line.write(_audioData, 0, _audioData.length);
        //nBytesWritten += line.write(_audioData, i * chunk, chunk);
        Log.println(false, "PlaybackThread.play() Bytes written: " + nBytesWritten);
        if ((_parent != null) && (_shouldRun))
        {
          _parent.setProgressValue(nBytesWritten);
        }
      }
    }
    /*
    if ((nBytesWritten < _audioData.length) && (_shouldRun))
    {
      nBytesWritten += line.write(_audioData, i * chunk, _audioData.length - nBytesWritten);
      Log.println(false, "PlaybackThread.play() Bytes written: " + nBytesWritten);
      if ((_parent != null) && (_shouldRun))
      {
        _parent.setProgressValue(nBytesWritten);
      }
      */
    //}
    /*
     * Wait until all data are played. This is only necessary because of the bug
     * noted below. (If we do not wait, we would interrupt the playback by
     * prematurely closing the line and exiting the VM.)
     * 
     * Thanks to Margie Fitch for bringing me on the right path to this
     * solution.
     */
    if (_shouldRun)
    {
      line.drain();
      while (line.getFramePosition() < nBytesWritten)
      {
        System.out.println("line active... position:" + line.getFramePosition());
        try
        {
          Thread.sleep(100);
        }
        catch (InterruptedException e)
        {
          Log.printStackTrace(e);
        }
      }
      Log.println(false, "PlaybackThread.play() Done playing.");
      /*
       * All data are played. We can close up shop.
       */
      line.close();
      if ((_parent != null) && (_shouldRun))
      {
        endTime = new GregorianCalendar();
        diffMillis = (float) (endTime.getTimeInMillis() - startTime.getTimeInMillis()) / (float) 1000;
        _parent.setSecondaryText(Messages.getString("CommsThread.22") + " in " + diffMillis + " seconds.");
        Log.println(true, "Text file sent in " + (float) (endTime.getTimeInMillis() - startTime.getTimeInMillis())
            / (float) 1000 + " seconds.");
        Log.println(false, "PlaybackThread.play() exit.");
      }
    }
  }
}
