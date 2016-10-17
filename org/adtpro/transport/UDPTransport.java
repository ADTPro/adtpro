/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006 - 2016 by David Schmidt
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

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;

import org.adtpro.resources.Messages;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.UnsignedByte;

public class UDPTransport extends ATransport
{
  protected boolean _connected;

  String _serverIP;

  int _port, _inPacketPtr = 0, _inPacketLen = 0, _outPacketPtr = 0;

  DatagramSocket _socket;
  DatagramPacket _packet;

  byte[] _receiveBuffer = null;
  byte[] _sendBuffer = null;
  static byte _packetNum = 1;

  public UDPTransport(String port) throws Exception
  {
    try
    {
      _port = Integer.parseInt(port);
    }
    catch (NumberFormatException e)
    {
      _port = 6502;
    }
    _connected = false;
    _packet = new DatagramPacket(new byte[1500],1500);
    _sendBuffer = new byte[1500];
  }

  public int transportType()
  {
    return TRANSPORT_TYPE_UDP;
  }
  
  public byte readByte(int seconds) throws TransportTimeoutException
  {
    //Log.println(false,"UDPTransport.readByte() entry; _inPacketPtr = "+_inPacketPtr+"; _inPacketLen = "+_inPacketLen+".");
    if (_receiveBuffer == null)
    {
      Log.println(false,"UDPTransport.readByte() needs to pull a buffer; buffer is null.");
      try
      {
        pullBuffer(seconds);
      }
      catch (java.net.SocketTimeoutException e1)
      {
        throw (new TransportTimeoutException());
      }
      catch (Exception e2)
      {        
      }
    }
    if (_inPacketPtr + 1 > _inPacketLen)
    {
      // Log.println(false,"UDPTransport.readByte() needs to pull a buffer; we're out of data.");
      try
      {
        pullBuffer(seconds);
      }
      catch (java.net.SocketTimeoutException e1)
      {
        throw (new TransportTimeoutException());
      }
      catch (Exception e2)
      {
      }
    }
    return _receiveBuffer[_inPacketPtr++];
  }

  /**
   * Closes the UDP port.
   * 
   * @exception Exception
   *              any exception encountered is rethrown.
   */
  public synchronized void close() throws Exception
  {
    Log.println(false,"UDPTransport.close() entry.");
    if (_connected)
    {
      _connected = false;
      _socket.close();
      Log.println(true,"UDPTransport closed UDP port " + _port + "."); //$NON-NLS-1$ //$NON-NLS-2$
    }
    Log.println(false,"UDPTransport.close() exit.");
  }

  /**
   * Opens the UDP port.
   * 
   * @exception Exception
   *              any exception encountered is rethrown.
   */
  public void open() throws Exception
  {
    if (_connected)
    {
      return;
    }
    else
    {
      _socket = new DatagramSocket(_port);
      _connected = true;
      Log.println(true,"UDPTransport opened UDP port " + _port + " at address " + InetAddress.getLocalHost().getHostAddress() ); //$NON-NLS-1$ //$NON-NLS-2$
      return;
    }
  }

  /**
   * Writes an array of bytes into a packet.
   * 
   * @param data
   *          the bytes to be written to the serial port.
   */
  public void writeBytes(byte data[])
  {
    //Log.println(false,"UDPTransport.writeBytes() entry.");
    if ((1500 - _outPacketPtr) >= data.length)
    {
      //Log.println(false,"UDPTransport.writeBytes() writing "+data.length+" bytes into packet starting from "+_outPacketPtr+".");
      if (_outPacketPtr == 0)
      {
        _packetNum++;
        //Log.println(false,"Setting sequence number to: "+ UnsignedByte.intValue(_packetNum));
        _sendBuffer[_outPacketPtr++] = _packetNum;
      }
      for (int i = 0; i < data.length; i++)
      {
        _sendBuffer[_outPacketPtr++] = data[i];
        //Log.println(false,"  data to buffer: "+data[i]);
      }
    }
    else
      Log.println(false,"UDPTransport.writeBytes() didn't have room!");
  }

  public void writeBytes(char[] data)
  {
    if ((1499 - _outPacketPtr) >= data.length)
    {
      if (_outPacketPtr == 0)
      {
        _packetNum++;
        _sendBuffer[_outPacketPtr++] = _packetNum;
      }
      for (int i = 0; i < data.length; i++)
      {
        _sendBuffer[_outPacketPtr++] = (byte) data[i];
      }
    }
  }

  public void writeBytes(String str)
  {
    writeBytes(str.getBytes());
  }

  public void writeByte(char datum)
  {
    byte data[] = { (byte)datum };
    writeBytes(data);
  }

  public void writeByte(int datum)
  {
    byte data[] = { (byte)datum };
    writeBytes(data);
  }

  public void writeByte(byte datum)
  {
    byte data[] = { datum };
    writeBytes(data);
  }

  public void pushBuffer()
  {
    Log.println(false,"UDPTransport.pushBuffer() entry.");
    Log.println(false, "UDPTransport.pushBuffer() pushing "+_outPacketPtr+" bytes of data:");
    for (int i = 0; i < _outPacketPtr; i++)
    {
      if (((i % 32) == 0) && (i != 0)) Log.println(false, "");
      Log.print(false, UnsignedByte.toString(_sendBuffer[i]) + " ");
    }
    Log.println(false, "");

    _packet.setData(_sendBuffer,0,_outPacketPtr);
    try
    {
      _socket.send(_packet);
    }
    catch (Exception e)
    {
      Log.printStackTrace(e);
    }
    _outPacketPtr = 0;
    Log.println(false,"UDPTransport.pushBuffer() exit.");
  }

  public void pullBuffer(int seconds) throws Exception
  {
    // Log.println(false,"UDPTransport.pullBuffer() entry.");
    _receiveBuffer = new byte[1500];
    _packet.setData(_receiveBuffer);
    _socket.setSoTimeout(seconds*1000);
    _socket.receive(_packet);
    Log.println(false,"UDPTransport.pullBuffer() received a packet.");
    _receiveBuffer = _packet.getData();
    _inPacketLen = _packet.getLength();
    _inPacketPtr = 0;
    Log.println(false, "UDPTransport.pullBuffer() pulled data:");
    for (int i = 0; i < _inPacketLen; i++)
    {
      if (((i % 32) == 0) && (i != 0)) Log.println(false, "");
      Log.print(false, UnsignedByte.toString(_receiveBuffer[i]) + " ");
    }
    Log.println(false, "");
  }

  public void flushReceiveBuffer()
  {
    _receiveBuffer = null;
  }

  public void flushSendBuffer()
  {
    _outPacketPtr = 0;
  }

  public void setSpeed(int speed)
  {
    // Unnecessary, unimplemented
  }

  public void setFullSpeed()
  {
    // Unnecessary, unimplemented
  }

  public void setFullSpeed(int speed)
  {
    // Unnecessary, unimplemented
  }

  public void setSlowSpeed(int speed)
  {
    // Unnecessary, unimplemented
  }

  public boolean supportsBootstrap()
  {
    return false;
  }

  public void pauseIncorrectCRC()
  {
    // Only necessary for audio transport
  }

  public String getInstructions(String guiString, int fileSize, int serialSpeed)
  {
    // Shouldn't be needed unless we eventually support bootstrapping over UDP.
    String ret = "UDPTransport.getInstructions() - returned null!";
    if (guiString.equals(Messages.getString("Gui.BS.DOS")))
      Messages.getString("Gui.BS.DumpDOSInstructions");
    else if (guiString.equals(Messages.getString("Gui.BS.ADT")))
      Messages.getString("Gui.BS.DumpADTInstructions");
    else if (guiString.equals(Messages.getString("Gui.BS.ADTPro")))
      Messages.getString("Gui.BS.DumpProInstructions");
    return ret;
  }

  public String getInstructionsDone(String guiString)
  {
    // Shouldn't be needed unless we eventually support bootstrapping over UDP.
    return "";
  }

}
