/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006 by David Schmidt
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

  int _timeout = 0;

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
  
  public byte readByte(int timeout) throws Exception
  {
    return readByte();
  }

  public byte readByte() throws Exception
  {
    Log.println(false,"readByte() entry; _inPacketPtr = "+_inPacketPtr+"; _inPacketLen = "+_inPacketLen+".");
    if (_receiveBuffer == null)
    {
      Log.println(false,"readByte() needs to pull a buffer; buffer is null.");
      try
      {
        pullBuffer(_timeout);
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
      Log.println(false,"UDPTransport.readByte() needs to pull a buffer; we're out of data.");
      try
      {
        pullBuffer(_timeout);
      }
      catch (java.net.SocketTimeoutException e1)
      {
        throw (new TransportTimeoutException());
      }
      catch (Exception e2)
      {
      }
    }
    int myByte = _receiveBuffer[_inPacketPtr];
    if (myByte < 0)
      myByte += 256;
    Log.println(false,"UDPTransport.readByte() exit with " + myByte);
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
    Log.println(false,"UDPTransport.writeBytes() entry.");
    if ((1499 - _outPacketPtr) >= data.length)
    {
      Log.println(false,"UDPTransport.writeBytes() writing "+data.length+" bytes into packet starting from "+_outPacketPtr+".");
      if (_outPacketPtr == 0)
      {
        _packetNum++;
        Log.println(false,"Setting sequence number to: "+ UnsignedByte.intValue(_packetNum));
        _sendBuffer[_outPacketPtr++] = _packetNum;
      }
      for (int i = 0; i < data.length; i++)
      {
        _sendBuffer[_outPacketPtr++] = data[i];
        //Log.println(false,"  data to buffer: "+data[i]);
      }
    }
    //else
      //Log.println(false,"DEBUG: UDPTransport.writeBytes() didn't have room!");
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
    /*
    Log.println(false,"Data:");
    for (int i = 0; i < _outPacketPtr; i++)
    {
      int j = i - 1;
      if ((j % 32) == 0)
        Log.println(false,"");
      System.out.print(UnsignedByte.toString(_sendBuffer[i])+" ");
    }
    Log.println(false,"");
    */
    //String fred = new String(_sendBuffer,0,_outPacketPtr);
    //Log.println(false,"Sending: "+fred);

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

  public void pullBuffer(int timeout) throws Exception
  {
    Log.println(false,"UDPTransport.pullBuffer() entry.");
    _receiveBuffer = new byte[1500];
    _packet.setData(_receiveBuffer);
    _socket.setSoTimeout(timeout);
    _socket.receive(_packet);
    Log.println(false,"received packet.");
    _socket.connect(_packet.getSocketAddress());
    Log.println(false,"connected to socket.");
    _receiveBuffer = _packet.getData();
    _inPacketLen = _packet.getLength();
    _inPacketPtr = 0;
    Log.println(false,"data: ["+new String (_receiveBuffer)+ "]");
    /*
    for (int i = 0; i < _inPacketLen; i++)
    {
      if ((i % 32) == 0)
        Log.println(false,"");
      Log.print(false,UnsignedByte.toString(_receiveBuffer[i])+" ");
    }
    Log.println(false,"");

    Log.println(false,"UDPTransport.pullBuffer() exit; _inPacketLen = "+_inPacketLen);
    */
  }

  public void flushReceiveBuffer()
  {
    _receiveBuffer = null;
  }

  public void flushSendBuffer()
  {
    _outPacketPtr = 0;
  }

  public boolean hasPreamble()
  {
    return true;
  }

  public void setFullSpeed()
  {
  }

  public void setSlowSpeed(int speed)
  {
  }

  public boolean supportsBootstrap()
  {
    return false;
  }

  public void setTimeout(int timeout)
  {
    _timeout = timeout;
  }

  public void pauseIncorrectCRC()
  {
    // Only necessary for audio transport
  }

  public String getInstructions(String guiString, int fileSize)
  {
    String ret = "UDPTransport.getInstructions() - returned null!";
    if (guiString.equals(Messages.getString("Gui.BS.DOS")))
      Messages.getString("Gui.BS.DumpDOSInstructions");
    else if (guiString.equals(Messages.getString("Gui.BS.ADT")))
      Messages.getString("Gui.BS.DumpADTInstructions");
    else if (guiString.equals(Messages.getString("Gui.BS.ADTPro")))
      Messages.getString("Gui.BS.DumpProInstructions");
    return ret;
  }
}
