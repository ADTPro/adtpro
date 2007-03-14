package org.adtpro.transport.audio;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.SourceDataLine;
import javax.sound.sampled.TargetDataLine;

import org.adtpro.utilities.Log;

// Inner class to capture audio data
public class CaptureThread extends Thread
{
  // An arbitrary-size temporary holding
  // buffer
  byte tempBuffer[] = new byte[10000];

  boolean dataYet = false;

  byte previousByte = 0x00;

  ByteArrayOutputStream outputStream;

  ByteArrayOutputStream outputBits;

  AudioFormat audioFormat;

  TargetDataLine targetDataLine;

  SourceDataLine sourceDataLine;

  boolean stopCapture = false;

  int crossState = 0; // 0 = indeterminate state

  int newState = 0;

  int freq = 0;

  int numBytesSinceLastCross = 0;

  int prevFreq = 0;

  boolean training = true;

  public void run()
  {
    Log.println(false, "CaptureThread.run() entry.");
    try
    {
      // Get everything set up for capture
      audioFormat = getAudioFormat();
      DataLine.Info dataLineInfo = new DataLine.Info(TargetDataLine.class, audioFormat);
      targetDataLine = (TargetDataLine) AudioSystem.getLine(dataLineInfo);
      targetDataLine.open(audioFormat);
      targetDataLine.start();
    }
    catch (Exception e)
    {
      Log.printStackTrace(e);
    }// end catch
    outputStream = new ByteArrayOutputStream();
    outputBits = new ByteArrayOutputStream();
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
        int cnt = targetDataLine.read(tempBuffer, 0, tempBuffer.length);
        if (cnt > 0)
        {
          interpretStream(tempBuffer);
        }// end if
      }// end while
      outputStream.close();
      outputBits.close();
    }
    catch (IOException e)
    {
      Log.printStackTrace(e);
    }// end catch
    Log.println(false, "CaptureThread.run() exit.");
  }// end run

  void interpretStream(byte buffer[])
  {
    // Log.println(false,"CaptureThread.interpretStream() entry.");
    // Need to track:
    // - bit position we're working on
    // - number of bytes since last zero cross
    // - state: training, pulling
    for (int i = 0; i < buffer.length; i++)
    {
      // Log.println(false,buffer[i]);
      numBytesSinceLastCross++;
      if (buffer[i] > 0)
      {
        prevFreq = freq;
        newState = 1;
        if (crossState != newState)
        {
          crossState = newState;
          freq = numBytesSinceLastCross;
          numBytesSinceLastCross = 0;
        }
      }
      else
        if (buffer[i] < 0)
        {
          newState = -1;
          if (crossState != newState)
          {
            prevFreq = freq;
            crossState = newState;
            freq = numBytesSinceLastCross;
            numBytesSinceLastCross = 0;
          }
        }
      if (numBytesSinceLastCross == 0)
      {
        // Log.println(false,"Freq: " + freq + " Previous Freq: " + prevFreq);
        if ((freq <= 9) && (freq > 2) && (training))
        {
          training = false;
          // Log.println(false,"Training done.");
          numBytesSinceLastCross = 0;
          freq = 0;
          prevFreq = 0;
        }
        else
          if ((freq > 25) && (!training))
          {
            // Log.println(false,"Training(1)...");
            training = true;
            numBytesSinceLastCross = 0;
            dataYet = false;
            freq = 0;
            prevFreq = 0;
          }
          else
            if ((freq <= prevFreq + 2) && (freq >= prevFreq - 2))
            {
              switch (freq)
              {
                case 27: // 770Hz
                case 28: // 770Hz
                case 29: // 770Hz
                  if (training == false)
                  {
                    training = true;
                    freq = 0;
                    dataYet = false;
                    // Log.println(false,"Training(2)...");
                  }
                  break;
                case 10: // 2000Hz
                case 11: // 2000Hz
                case 12: // 2000Hz
                  if (training == false)
                  {
                    freq = 0;
                    pushBit(0);
                  }
                  break;
                case 21: // 1000Hz
                case 22: // 1000Hz
                case 23: // 1000Hz
                  if (training == false)
                  {
                    freq = 0;
                    pushBit(1);
                  }
                  break;
                default:
                  if (!training)
                  {
                    Log.println(false, "Unexpected frequency: " + freq);
                  }
                  break;
              }
            }
      }
    }
  }

  public int receiveBufferSize()
  {
    int mySize = 0;
    if (outputStream != null)
    {
      mySize = outputStream.size();
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
          outputStream.reset();
        }
      }
    }
    if (returnValue == null)
      returnValue = new byte[0];
    return returnValue;
  }

  public void pushBit(int bit)
  {
    outputBits.write(bit);
    if (outputBits.size() == 8)
    {
      byte fred[] = outputBits.toByteArray();
      byte completedByte = 0x00;
      for (int i = 0; i < 8; i++)
      {
        completedByte = (byte) (completedByte + (fred[i] << (7 - i)));
      }
      if (dataYet)
      {
        // Log.println(false,"Pushing completed byte:
        // "+UnsignedByte.toString(previousByte)+", delaying most recent byte
        // "+UnsignedByte.toString(completedByte));
        outputStream.write(previousByte);
      }
      // else
      // Log.println(false,"Delaying completed byte:
      // "+UnsignedByte.toString(completedByte));

      previousByte = completedByte;
      outputBits.reset();
      dataYet = true;
    }
  }

  public void flushReceiveBuffer()
  {
    Log.println(false, "CaptureThread.flushReceiveBuffer() entry.");
    synchronized (outputStream)
    {
      outputStream.reset();
    }
    outputBits.reset();
    Log.println(false, "CaptureThread.flushReceiveBuffer() exit.");
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
  private AudioFormat getAudioFormat()
  {
    float sampleRate = 44100.0F; // 8000,11025,16000,22050,44100
    int sampleSizeInBits = 8; // 8,16
    int channels = 1; // 1,2
    boolean signed = true; // true,false
    boolean bigEndian = false; // true,false
    return new AudioFormat(sampleRate, sampleSizeInBits, channels, signed, bigEndian);
  }// end getAudioFormat

}