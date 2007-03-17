/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006, 2007 by David Schmidt
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

public abstract class ATransport
{
  public abstract int transportType();
  public abstract void open() throws Exception;
  public abstract void setSlowSpeed(int speed);
  public abstract void setFullSpeed();
  public abstract void writeByte(byte datum);
  public abstract void writeByte(char datum);
  public abstract void writeByte(int datum);
  public abstract void writeBytes(byte data[]);
  public abstract void writeBytes(char data[]);
  public abstract void writeBytes(String str);
  //public abstract byte readByte() throws Exception;
  public abstract byte readByte(int timeout) throws TransportTimeoutException;
  public abstract void pauseIncorrectCRC();
  public abstract void pushBuffer();
  public abstract void flushSendBuffer();
  public abstract void flushReceiveBuffer();
  public abstract void close() throws Exception;
  public abstract boolean hasPreamble();
  public abstract boolean supportsBootstrap();
  public abstract String getInstructions(String guiString, int fileSize);
  public static final int TRANSPORT_TYPE_SERIAL = 1;
  public static final int TRANSPORT_TYPE_UDP = 2;
  public static final int TRANSPORT_TYPE_AUDIO = 3;
}
