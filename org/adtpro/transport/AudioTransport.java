/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 by David Schmidt
 * david__schmidt at users.sourceforge.net
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

package org.adtpro.transport;

import org.adtpro.CommsThread;
import org.adtpro.gui.Gui;
import org.adtpro.resources.Messages;
import org.adtpro.transport.audio.BytesToWav;
import org.adtpro.transport.audio.CaptureThread;
import org.adtpro.transport.audio.PlaybackThread;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.UnsignedByte;

public class AudioTransport extends ATransport
{
  int _inPacketPtr = 0, _inPacketLen = 0, _outPacketPtr = 0, _bigOutPacketPtr = 0;

  int _timeout = 0;

  byte[] _receiveBuffer = null;

  byte[] _sendBuffer = null;

  byte[] _bigBuffer = null;

  CaptureThread _captureThread = null;

  PlaybackThread _sendThread = null;

  public void open() throws Exception
  {
    Log.getSingleton();
    Log.println(false, "AudioTransport.open() entry...");
    _captureThread = new CaptureThread();
    _captureThread.start();
    Log.println(true, "AudioTransport opened.");
    _sendBuffer = new byte[1500];
    Log.println(false, "AudioTransport.open() exit.");
  }

  public int transportType()
  {
    return TRANSPORT_TYPE_AUDIO;
  }
  
  public void setSlowSpeed(int speed)
  {
  // Unnecessary, unimplemented
  }

  public void setFullSpeed()
  {
  // Unnecessary, unimplemented
  }

  /**
   * Writes an array of bytes into a packet.
   * 
   * @param data
   *          the bytes to be written to the serial port.
   */
  public void writeBytes(byte data[])
  {
    Log.println(false, "AudioTransport.writeBytes() entry.");
    if ((1499 - _outPacketPtr) >= data.length)
    {
      Log.println(false, "AudioTransport.writeBytes() writing " + data.length + " bytes into packet starting from "
          + _outPacketPtr + ".");
      for (int i = 0; i < data.length; i++)
      {
        _sendBuffer[_outPacketPtr++] = data[i];
        // Log.println(false," data to buffer: "+data[i]);
      }
    }
    else
      Log.println(false, "AudioTransport.writeBytes() didn't have room!");
  }

  public void writeBytes(char[] data)
  {
    if ((1499 - _outPacketPtr) >= data.length)
    {
      for (int i = 0; i < data.length; i++)
      {
        _sendBuffer[_outPacketPtr++] = (byte) data[i];
      }
    }
    else
      Log.println(true, "AudioTransport.writeBytes(char[]) - buffer too large!");
  }

  public void writeBigBytes(byte[] data)
  {
    _bigBuffer = new byte[data.length];
    for (int i = 0; i < data.length; i++)
    {
      _bigBuffer[_bigOutPacketPtr++] = data[i];
    }

  }

  public void writeBytes(String str)
  {
    writeBytes(str.getBytes());
  }

  public void writeByte(char datum)
  {
    byte data[] =
    { (byte) datum };
    writeBytes(data);
  }

  public void writeByte(int datum)
  {
    byte data[] =
    { (byte) datum };
    writeBytes(data);
  }

  public void writeByte(byte datum)
  {
    byte data[] =
    { datum };
    writeBytes(data);
  }

  public byte readByte(int timeout) throws Exception
  {
    if (timeout >= 0) _timeout = timeout;
    return readByte();
  }

  public byte readByte() throws Exception
  {
    byte retByte = 0;
    Log.println(false, "AudioTransport.readByte() entry; _inPacketPtr = " + _inPacketPtr + "; _inPacketLen = "
        + _inPacketLen + ".");
    if (_receiveBuffer == null)
    {
      Log.println(false, "AudioTransport.readByte() needs to pull a buffer; buffer is null.");
      try
      {
        pullBuffer(_timeout);
      }
      catch (java.net.SocketTimeoutException e1)
      {
        throw (new TransportTimeoutException());
      }
      catch (Exception e2)
      {}
    }
    if (_inPacketPtr + 1 > _inPacketLen)
    {
      Log.println(false, "AudioTransport.readByte() needs to pull a buffer; we're out of data.");
      try
      {
        pullBuffer(_timeout);
      }
      catch (java.net.SocketTimeoutException e1)
      {
        throw (new TransportTimeoutException());
      }
      catch (TransportClosedException e2)
      {}
    }
    if (_receiveBuffer != null)
    {
      if ((_inPacketPtr <= _receiveBuffer.length) && (_receiveBuffer.length > 0))
      {
        int myByte = _receiveBuffer[_inPacketPtr];
        if (myByte < 0) myByte += 256;
        Log.println(false, "AudioTransport.readByte() exit with " + UnsignedByte.toString(UnsignedByte.loByte(myByte)));
      }
      if (_receiveBuffer.length > 0) retByte = _receiveBuffer[_inPacketPtr++];
      else
        retByte = 0;
    }
    return retByte;
  }

  public void pushBuffer()
  {
    Log.println(false, "AudioTransport.pushBuffer() entry, pushing " + _outPacketPtr + " bytes.");
    Log.println(false, "AudioTransport.pushBuffer() pushing data:");
    for (int i = 0; i < _outPacketPtr; i++)
    {
      if (((i % 32) == 0) && (i != 0)) Log.println(false, "");
      Log.print(false, UnsignedByte.toString(_sendBuffer[i]) + " ");
    }
    Log.println(false, "");
    byte[] stuff = BytesToWav.encode(_sendBuffer, _outPacketPtr);
    if (_sendThread != null)
    {
      try
      {
        _sendThread.join();
      }
      catch (InterruptedException e)
      {
        Log.printStackTrace(e);
      }
    }
    _sendThread = new PlaybackThread(stuff);
    _sendThread.play();
    _outPacketPtr = 0;
    Log.println(false, "AudioTransport.pushBuffer() exit.");
    _inPacketLen = 0;
    _receiveBuffer = null;
    _inPacketPtr = 0;
  }

  public void pushBigBuffer(Gui parent)
  {
    Log.println(false, "AudioTransport.pushBigBuffer() entry, pushing " + _bigBuffer.length + " bytes.");
    Log.println(false, "AudioTransport.pushBigBuffer() pushing data:");
    for (int i = 0; i < _bigBuffer.length; i++)
    {
      if (((i % 32) == 0) && (i != 0)) Log.println(false, "");
      Log.print(false, UnsignedByte.toString(_bigBuffer[i]) + " ");
    }
    Log.println(false, "");
    byte[] stuff = BytesToWav.encode(_bigBuffer, _bigOutPacketPtr, 7000);
    if (_sendThread != null)
    {
      try
      {
        _sendThread.join();
      }
      catch (InterruptedException e)
      {
        Log.printStackTrace(e);
      }
    }
    _sendThread = new PlaybackThread(stuff, parent);
    _sendThread.play();
    _bigOutPacketPtr = 0;
    _bigBuffer = null;
    Log.println(false, "AudioTransport.pushBigBuffer() exit.");
  }

  public void pullBuffer(int timeout) throws Exception
  {
    Log.println(false, "AudioTransport.pullBuffer() entry; timeout = " + timeout + " _timeout = " + _timeout);
    int numTimeouts = 0;
    if (timeout == -1) timeout = _timeout;
    while ((_captureThread != null) && ((_captureThread.receiveBufferSize()) == 0)
        && ((100 * numTimeouts < timeout) || timeout == 0))
    {
      if (timeout > 0) Log.println(false, "AudioTransport.pullBuffer sleeping... numTimeouts: " + numTimeouts * 100
          + " requested: " + timeout);
      Thread.sleep(100);
      numTimeouts++;
    }
    if (_captureThread != null)
    {
      if ((_captureThread.receiveBufferSize() == 0) && (timeout > 0)) { throw new TransportTimeoutException(); }
      if (_captureThread.receiveBufferSize() > 0)
      {
        _receiveBuffer = _captureThread.retrieveReceiveBuffer();
        _inPacketLen = _receiveBuffer.length;
        _inPacketPtr = 0;
        Log.println(false, "AudioTransport.pullBuffer() pulled data:");
        for (int i = 0; i < _inPacketLen; i++)
        {
          if (((i % 32) == 0) && (i != 0)) Log.println(false, "");
          Log.print(false, UnsignedByte.toString(_receiveBuffer[i]) + " ");
        }
      }
      Log.println(false, "");
    }
    else
      throw new TransportClosedException();
    Log.println(false, "AudioTransport.pullBuffer() exit; _inPacketLen = " + _inPacketLen);
  }

  public void flushSendBuffer()
  {
    Log.println(false, "AudioTransport.flushSendBuffer() entry.");
    _outPacketPtr = 0;
    Log.println(false, "AudioTransport.flushSendBuffer() exit.");
  }

  public void flushReceiveBuffer()
  {
    Log.println(false, "AudioTransport.flushReceiveBuffer() entry.");
    if (_captureThread != null) _captureThread.flushReceiveBuffer();
    Log.println(false, "AudioTransport.flushReceiveBuffer() exit.");
  }

  public void close() throws Exception
  {
    Log.println(false, "AudioTransport.close() entry.");
    // Stop the audio capture thread
    if (_captureThread != null)
    {
      _captureThread.requestStop();
      _captureThread = null;
    }
    if (_sendThread != null)
    {
      _sendThread.requestStop();
      _sendThread = null;
    }
    _sendBuffer = null;
    Log.println(true, "AudioTransport closed.");
    Log.println(false, "AudioTransport.close() exit.");
  }

  public boolean hasPreamble()
  {
    return true;
  }

  public boolean supportsBootstrap()
  {
    return true;
  }

  public void pauseIncorrectCRC()
  {
    try
    {
      Log.getSingleton();
      Log.println(false, "Pausing for an incorrect CRC...");
      Thread.sleep(4000);
      Log.println(false, "Done pausing.");
    }
    catch (InterruptedException e)
    {
      Log.printStackTrace(e);
    }

  }

  public String getInstructions(String guiString, int fileSize)
  {
    String ret = "AudioTransport.getInstructions() - returned null!";
    int endAddr = 0;
    if (guiString.equals(Messages.getString("Gui.BS.DOS"))) ret = Messages.getString("Gui.BS.DumpDOSAudioInstructions");
    else
      if (guiString.equals(Messages.getString("Gui.BS.DOS2"))) ret = Messages
          .getString("Gui.BS.DumpDOSAudioInstructions2");
      else
        if (guiString.equals(Messages.getString("Gui.BS.ADT")))
        {
          ret = Messages.getString("Gui.BS.DumpADTAudioInstructions");
          endAddr = fileSize - 1 + 2051;
          String endAddrHex = UnsignedByte.toString(UnsignedByte.hiByte(endAddr))+UnsignedByte.toString(UnsignedByte.loByte(endAddr));
          ret = ret.replaceFirst("%1%",endAddrHex);
        }
        else
          if (guiString.equals(Messages.getString("Gui.BS.ADTPro")))
          {
            ret = Messages.getString("Gui.BS.DumpProAudioInstructions");
            endAddr = fileSize - 1 + 2051;
            String endAddrHex = UnsignedByte.toString(UnsignedByte.hiByte(endAddr))+UnsignedByte.toString(UnsignedByte.loByte(endAddr));
            ret = ret.replaceFirst("%1%",endAddrHex);
          }
          else
            if (guiString.equals(Messages.getString("Gui.BS.ADTProAudio")))
            {
              ret = Messages.getString("Gui.BS.DumpProAudioAudioInstructions");
              endAddr = fileSize - 1 + 2051;
              String endAddrHex = UnsignedByte.toString(UnsignedByte.hiByte(endAddr))+UnsignedByte.toString(UnsignedByte.loByte(endAddr));
              ret = ret.replaceFirst("%1%",endAddrHex);
            }
    return ret;
  }
}