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

import java.io.*;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.util.*;

import org.adtpro.resources.Messages;

public class UDPTransport extends ATransport
{
  protected boolean _connected;

  String _serverIP;

  int _port, _inPacketPtr = 0, _inPacketLen = 0, _outPacketPtr = 0;

  DatagramSocket _socket;

  DatagramPacket _packet;

  byte[] _receiveBuffer = null;
  byte[] _sendBuffer = null;

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

  public byte readByte() throws Exception
  {
    System.out.println("DEBUG: readByte() entry; _inPacketPtr = "+_inPacketPtr+"; _inPacketLen = "+_inPacketLen+".");
    if (_receiveBuffer == null)
    {
      System.out.println("DEBUG: readByte() needs to pull a buffer; buffer is null.");
      pullBuffer();
    }
    if (_inPacketPtr + 1 > _inPacketLen)
    {
      System.out.println("DEBUG: readByte() needs to pull a buffer; we're out of data.");
      pullBuffer();
    }
    int myByte = _receiveBuffer[_inPacketPtr];
    if (myByte < 0)
      myByte += 256;
    System.out.println("DEBUG: readByte() exit with " + myByte);
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
    // System.out.println("DEBUG: UDPTransport.close() entry.");
    if (_connected)
    {
      _connected = false;
      _socket.close();
      System.out.println("UDPTransport closed UDP port " + _port + "."); //$NON-NLS-1$ //$NON-NLS-2$
    }
    // System.out.println("DEBUG: UDPTransport.close() exit.");
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
      System.out.println("UDPTransport opened UDP port " + _port + " at address " + _socket.getLocalAddress().getHostAddress() ); //$NON-NLS-1$ //$NON-NLS-2$
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
    //System.out.println("DEBUG: UDPTransport.writeBytes() entry.");
    if ((1500 - _outPacketPtr) >= data.length)
    {
      System.out.println("DEBUG: UDPTransport.writeBytes() writing "+data.length+" bytes into packet starting from "+_outPacketPtr+".");
      for (int i = 0; i < data.length; i++)
      {
        _sendBuffer[_outPacketPtr++] = data[i];
        //System.out.println("  data to buffer: "+data[i]);
      }
    }
    else
      System.out.println("DEBUG: UDPTransport.writeBytes() didn't have room!");
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
    System.out.println("DEBUG: pushBuffer() entry.");

    System.out.println("Data:");
    for (int i = 0; i < _outPacketPtr; i++)
    {
      int j = _sendBuffer[i];
      if (j < 0)
        j += 256;
      System.out.print(j+" ");
    }
    System.out.println("");
    //String fred = new String(_sendBuffer,0,_outPacketPtr);
    //System.out.println("Sending: "+fred);

    _packet.setData(_sendBuffer,0,_outPacketPtr);
    try
    {
      _socket.send(_packet);
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
    _outPacketPtr = 0;
    System.out.println("DEBUG: pushBuffer() exit.");
  }

  public void pullBuffer() throws Exception
  {
    System.out.println("DEBUG: pullBuffer() entry.");
    _receiveBuffer = new byte[1500];
    _packet.setData(_receiveBuffer);
    _socket.receive(_packet);
    System.out.println("DEBUG: received packet.");
    _receiveBuffer = _packet.getData();
    _inPacketLen = _packet.getLength();
    _inPacketPtr = 0;
    System.out.println("DEBUG: pullBuffer() exit; _inPacketLen = "+_inPacketLen);
  }
}
