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
import java.util.*;

import gnu.io.*;

public class SerialTransport
{
  protected CommPortIdentifier portId;

  protected SerialPort port;

  protected DataInputStream inputStream;

  protected DataOutputStream outputStream;

  protected boolean connected;

  protected String portName = null;

  /**
   * Create a new instance of the Comm API Transport. This constructor creates a
   * new instance of the Comm API Transport.
   * 
   * @param portName
   *          A string representing the Comm Port to be used.
   * @param speed
   * @throws NoSuchPortException
   * @throws PortInUseException
   * @throws UnsupportedCommOperationException
   * @throws IOException
   * @exception Exception
   *              used to pass any exceptions thrown during initialization.
   */

  public SerialTransport(String portName, String speed) throws Exception
  {
    int portSpeed = Integer.parseInt(speed);
    System.out.println("SerialTransport opening port named " + portName + " at speed " + speed + ".");
    this.portName = portName;
    connected = false;
    portId = CommPortIdentifier.getPortIdentifier(portName);
    port = (SerialPort) portId.open("ADTProSerial", 100);
    port.setSerialPortParams(Integer.parseInt(speed), 8, 1, 0);
    port.setFlowControlMode(3);
    inputStream = new DataInputStream(port.getInputStream());
    outputStream = new DataOutputStream(port.getOutputStream());
    connected = true;
    System.out.println("SerialTransport initialized.");
  }

  /**
   * Closes the Java COMM API port.
   * 
   * @exception Exception
   *              any exception encountered is rethrown.
   */

  public synchronized void close() throws Exception
  {
    if (connected)
    {
      inputStream.skip(inputStream.available());
      inputStream.close();
      outputStream.close();
      port.close();
      connected = false;
    }
  }

  protected void finalize() throws Throwable
  {
    close();
  }

  /**
   * Flushes the input buffer of any remaining data.
   * 
   * @exception IOException
   *              thrown when a problem occurs with flushing the stream.
   */

  public void flush() throws IOException
  {
    while (inputStream.available() > 0)
    {
      inputStream.read();
    }
  }

  /**
   * Returns the name of this Transport Interface. This method will return a
   * string containing the name of this transport interface. This is used when
   * searching for and selecting from one of many available transport interfaces
   * that are installed on the system.
   * 
   * @return the name of this transport interface.
   */

  public static String getName()
  {
    return "Sun Java Communications API Bridge Class by Brad Barclay";
  }

  /**
   * Returns an array of Strings representing the names of available ports. This
   * method will return to the caller an array of strings representing the
   * serial ports available on this system.
   * 
   * @return an array of String representing the names of the available ports.
   */

  public static String[] getPortNames()
  {
    Vector v = new Vector();
    Enumeration enumeration = null;

    try
    {
      enumeration = CommPortIdentifier.getPortIdentifiers();
    }
    catch (NoClassDefFoundError ex)
    {
      System.out.println("Unable to find class \"CommPortIdentifier\"");
      return null;
    }

    while (enumeration.hasMoreElements())
    {
      v.addElement(((CommPortIdentifier) enumeration.nextElement()).getName());
    }

    String ret[] = new String[v.size()];
    for (int j = 0; j < v.size(); j++)
      ret[j] = (String) v.elementAt(j);
    return ret;
  }

  /**
   * Opens a read/write connection to the implemented transport. This method
   * should open the transport device being implemented using default
   * parameters.
   * 
   * @exception IOException
   *              thrown when a problem occurs with flushing the stream.
   */

  public void open() throws Exception
  {
    if (connected)
    {
      return;
    }
    else
    {
      port = (SerialPort) portId.open("ADTProSerial", 100);
      port.setSerialPortParams(115200, 8, 1, 0);
      port.setFlowControlMode(3);
      inputStream = new DataInputStream(port.getInputStream());
      outputStream = new DataOutputStream(port.getOutputStream());
      connected = true;
      return;
    }
  }

  /**
   * Read a single byte from the Java COMM API port.
   * 
   * @throws IOException
   */

  public byte readByte() throws IOException
  {
    // System.out.println("SERIAL READ BYTE STUBBED OUT");
    boolean hasData = false;
    byte oneByte = 0;

    while (hasData == false)
    {
      try
      {
        oneByte = inputStream.readByte();
        hasData = true;
      }
      catch (java.io.IOException e)
      {}
    }
    return oneByte;
  }

  /**
   * Sets the speed of the underlying Java COMM API port.
   * 
   * @param speed
   *          The speed to set the transport to.
   * @exception IOException
   *              thrown when a problem occurs with flushing the stream.
   */

  public void setSpeed(int speed) throws Exception
  {
    flush();
    port.setSerialPortParams(speed, 8, 1, 0);
  }

  /**
   * Writes an array of bytes to the Java COMM API port.
   * 
   * @param data
   *          the bytes to be written to the serial port.
   */

  public void writeBytes(byte data[], String log)
  {
    try
    {
      outputStream.write(data, 0, data.length);
    }
    catch (IOException ex)
    {}
  }

  public void writeBytes(String str)
  {
    writeBytes(str.getBytes(), "");
  }

  public void writeByte(int datum)
  {
    byte data[] =
    { (byte) (datum & 0xff) };
    writeBytes(data, "");
  }

  public void writeByte(byte datum)
  {
    byte data[] =
    { datum };
    writeBytes(data, "");
  }

  public void writeByte(byte datum, String str)
  {
    byte data[] =
    { datum };
    writeBytes(data, str);
  }
}
