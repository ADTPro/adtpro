/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006 - 2020 by David Schmidt
 * 1110325+david-schmidt@users.noreply.github.com
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

import jssc.SerialPort;
import jssc.SerialPortException;
import jssc.SerialPortList;
import jssc.SerialPortTimeoutException;

import org.adtpro.gui.Gui;
import org.adtpro.resources.Messages;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.StringUtilities;
import org.adtpro.utilities.UnsignedByte;

public class SerialTransport extends ATransport
{
  protected SerialPort port;

  protected boolean connected;

  protected String _portName = null;

  protected int _currentSpeed = 0;

  protected boolean _hardware = false;

  protected Gui _parent = null;

  int _outPacketPtr = 0;

  byte[] _sendBuffer = null;

  /**
   * Create a new instance of the Comm API Transport. This constructor creates a
   * new instance of the Comm API Transport.
   * 
   * @param portName
   *                   A string representing the Comm Port to be used.
   * @param speed
   * @throws NoSuchPortException
   * @throws PortInUseException
   * @throws UnsupportedCommOperationException
   * @throws IOException
   * @exception Exception
   *                        used to pass any exceptions thrown during
   *                        initialization.
   */

  public SerialTransport(Gui parent, String portName, String speed, boolean hardware) throws Exception
  {
    Log.getSingleton();
    Log.println(false, "SerialTransport constructor entry.");
    this._portName = portName;
    connected = false;
    _parent = parent;
    _hardware = hardware;
    _currentSpeed = Integer.parseInt(speed);
    _sendBuffer = new byte[32768];
    Log.println(false, "SerialTransport constructor exit.");
  }

  public int transportType()
  {
    return TRANSPORT_TYPE_SERIAL;
  }

  /**
   * Closes the Java COMM API port.
   * 
   * @exception Exception
   *                        any exception encountered is rethrown.
   */

  public synchronized void close() throws Exception
  {
    if (connected)
    {
      connected = false;
      Log.println(false, "SerialTransport.close() closing port..."); //$NON-NLS-1$
      port.closePort();
      port = null;
      Log.println(false, "SerialTransport.close() closed port."); //$NON-NLS-1$
      Log.println(true, "SerialTransport closed port."); //$NON-NLS-1$
    }
    else
      Log.println(false, "SerialTransport.close() didn't think port was connected."); //$NON-NLS-1$
  }

  /**
   * Returns an array of Strings representing the names of available ports. This
   * method will return to the caller an array of strings representing the serial
   * ports available on this system.
   * 
   * @return an array of String representing the names of the available ports.
   */

  public static String[] getPortNames()
  {
    Vector<String> v = new Vector<String>();

    String[] portNames = SerialPortList.getPortNames();
    for (int i = 0; i < portNames.length; i++)
    {
      v.addElement(portNames[i]);
    }

    String ret[] = new String[v.size()];
    for (int j = 0; j < v.size(); j++)
      ret[j] = v.elementAt(j);
    return ret;
  }

  /**
   * Opens a read/write connection to the implemented transport. This method
   * should open the transport device being implemented using default parameters.
   * 
   * @exception IOException
   *                          thrown when a problem occurs opening the stream.
   */

  public void open() throws Exception
  {
    if (connected)
    {
      return;
    }
    else
    {
      open(_portName, _currentSpeed, _hardware);
    }
  }

  /**
   * Opens a read/write connection to the implemented transport. This method
   * should open the transport device being implemented using default parameters.
   * 
   * @exception IOException
   *                          thrown when a problem occurs with opening the
   *                          stream.
   */
  public void open(String portName, int portSpeed, boolean hardware) throws Exception
  {
    Log.println(false, "SerialTransport.open() entry.");
    if (connected)
    {
      Log.println(false, "SerialTransport.open() was connected; closing.");
      close();
    }
    port = new SerialPort(portName);
    port.openPort();
    port.setParams(portSpeed, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    setHardwareHandshaking(hardware);
    port.purgePort(SerialPort.PURGE_RXCLEAR | SerialPort.PURGE_TXCLEAR);
    flushReceiveBuffer();
    connected = true;
    Log.println(true, "SerialTransport opened port named " + portName + " at speed " + portSpeed + "."); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
    return;
  }

  /**
   * Read a single byte from the Java COMM API port.
   * @throws SerialPortException 
   * 
   * @throws IOException
   */

  public byte readByte(int seconds) throws TransportTimeoutException
  {
    int collectedTimeouts = 0;
    boolean hasData = false;
    byte oneByte = 0;
    while ((hasData == false) && (connected))
    {
      try
      {
        oneByte = port.readBytes(1,seconds*1000)[0];
        hasData = true;
      }
      catch (SerialPortTimeoutException e)
      {
        collectedTimeouts++;
        //Log.printStackTrace(e);
      }
      catch (SerialPortException e)
      {
        Log.printStackTrace(e);
      }
      if (collectedTimeouts / 4 > seconds)
        throw new TransportTimeoutException();
    }
    /*
     * if (hasData) Log.println(false, "SerialTransport.readByte() exit, byte: " +
     * UnsignedByte.toString(oneByte)); else Log.println(false,
     * "SerialTransport.readByte() exit.");
     */
    return oneByte;
  }

  /**
   * Sets the parameters of the underlying Java COMM API port.
   * 
   * @param port
   *                   The port to set the parameters to.
   * @param speed
   *                   The speed to set the transport to.
   * @param hardware
   *                   Boolean to say if hardware handshaking should be used.
   * @exception IOException
   *                          thrown when a problem occurs with flushing the
   *                          stream.
   */

  public void setParms(String newPort, int newSpeed, boolean newHardware) throws Exception
  {
    if (!newPort.equals(_portName))
    {
      close();
      open(newPort, newSpeed, newHardware);
      _portName = newPort;
    }
    else
    {
      setHardwareHandshaking(newHardware);
      if (_currentSpeed != newSpeed)
      {
        flushReceiveBuffer();
        flushSendBuffer();
        _currentSpeed = newSpeed;
        port.setParams(newSpeed, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
      }
    }
  }

  /**
   * Sets the speed of the underlying Java COMM API rxtxPort.
   * 
   * @param speed
   *                The speed to set the transrxtxPort to.
   * @exception IOException
   *                          thrown when a problem occurs with flushing the
   *                          stream.
   */

  public void setSpeed(int speed)
  {
    if (_currentSpeed != speed)
    {
      try
      {
        flushReceiveBuffer();
        flushSendBuffer();
        _currentSpeed = speed;
        port.setParams(speed, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
      }
      catch (Exception e)
      {
        e.printStackTrace();
      }
    }
  }

  /**
   * Writes an array of bytes to the Java COMM API port.
   * 
   * @param data
   *               the bytes to be written to the serial port.
   */

  public void writeBytes(byte data[], String log)
  {
    Log.println(false, "SerialTransport.writeBytes() adding " + data.length + " bytes to the stream.");
    if (_outPacketPtr + data.length > _sendBuffer.length)
    {
      Log.println(false, "SerialTransport.writeBytes() Re-allocating the send buffer: " + _sendBuffer.length
          + " bytes is the new size.");
      byte newBuffer[] = new byte[_sendBuffer.length + data.length];
      for (int i = 0; i < _sendBuffer.length; i++)
        newBuffer[i] = _sendBuffer[i];
      _sendBuffer = new byte[newBuffer.length * 2];
      for (int i = 0; i < newBuffer.length; i++)
        _sendBuffer[i] = newBuffer[i];
      _outPacketPtr = newBuffer.length;
    }
    // Log.println(false, "SerialTransport.writeBytes() writing " + data.length
    // + " bytes into packet starting from " + _outPacketPtr + ".");
    for (int i = 0; i < data.length; i++)
    {
      _sendBuffer[_outPacketPtr++] = data[i];
    }
    if (_outPacketPtr > 255)
    {
      Log.println(false, "SerialTransport.writeBytes() has " + _outPacketPtr + " bytes to send.");
      pushBuffer();
    }
  }

  public void writeBytes(String str)
  {
    writeBytes(str.getBytes(), ""); //$NON-NLS-1$
  }

  public void writeBytes(byte[] data)
  {
    writeBytes(data, ""); //$NON-NLS-1$
  }

  public void writeBytes(char[] data)
  {
    byte[] bytes = new byte[data.length];
    for (int i = 0; i < data.length; i++)
      bytes[i] = (byte) data[i];
    writeBytes(bytes, ""); //$NON-NLS-1$
  }

  public void writeByte(char datum)
  {
    byte data[] =
    { (byte) (datum) };
    writeBytes(data, ""); //$NON-NLS-1$
  }

  public void writeByte(int datum)
  {
    byte data[] =
    { (byte) (datum & 0xff) };
    writeBytes(data, ""); //$NON-NLS-1$
  }

  public void writeByte(byte datum)
  {
    byte data[] =
    { datum };
    writeBytes(data, ""); //$NON-NLS-1$
  }

  public void writeByte(byte datum, String str)
  {
    byte data[] =
    { datum };
    writeBytes(data, str);
  }

  public void pullBuffer()
  {
    // Serial rxtxPort is byte-by-byte, no buffering
  }

  public void pushBuffer()
  {
    Log.println(false, "SerialTransport.pushBuffer() entry, pushing " + _outPacketPtr + " bytes.");
    if (_outPacketPtr > 0)
    {
      if (Log.getSingleton().isLogging())
      {
        Log.println(false, "SerialTransport.pushBuffer() pushing data:");
        for (int i = 0; i < _outPacketPtr; i++)
        {
          if (((i % 32) == 0) && (i != 0))
            Log.println(false, "");
          Log.print(false, UnsignedByte.toString(_sendBuffer[i]) + " ");
        }
        Log.println(false, "");
      }

      try
      {
        while (port.getOutputBufferBytesCount() > 1) {} // Moderate buffer speed
        if (_outPacketPtr == 1)
        {
          port.writeByte(_sendBuffer[0]);
        }
        else
        {
          byte newBuffer[] = new byte[_outPacketPtr];
          for (int i = 0; i < _outPacketPtr; i++)
            newBuffer[i] = _sendBuffer[i];
          port.writeBytes(newBuffer);
        }
      }
      catch (SerialPortException e)
      {
        Log.printStackTrace(e);
        e.printStackTrace();
      }
      _outPacketPtr = 0;
    }
    Log.println(false, "SerialTransport.pushBuffer() exit.");
  }

  public void flushReceiveBuffer()
  {
    // Actually flushing seems to be harmful; skip it
    /*
    try
    {
      port.purgePort(SerialPort.PURGE_RXCLEAR);
    }
    catch (SerialPortException e)
    {
      Log.println(false, "SerialTransport.flushReceiveBuffer() failed to purge the port.");
    }
    */
  }

  public void flushSendBuffer()
  {
    // Actually flushing seems to be harmful; skip it
    /*
    try
    {
      port.purgePort(SerialPort.PURGE_TXCLEAR);
    }
    catch (SerialPortException e)
    {
      Log.println(false, "SerialTransport.flushSendBuffer() failed to purge the port.");
    }
    */
  }

  public void setFullSpeed()
  {
    try
    {
      port.setParams(_currentSpeed, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    }
    catch (SerialPortException e)
    {
      Log.printStackTrace(e);
    }
  }

  public void setFullSpeed(int speed)
  {
    try
    {
      port.setParams(_currentSpeed, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    }
    catch (SerialPortException e)
    {
      Log.printStackTrace(e);
    }
  }

  public void setSlowSpeed(int speed)
  {
    Log.println(false, "SerialTransport.setSlowSpeed() setting speed to " + speed);
    try
    {
      port.setParams(speed, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    }
    catch (SerialPortException e)
    {
      Log.printStackTrace(e);
    }
  }

  public boolean supportsBootstrap()
  {
    return true;
  }

  public void pauseIncorrectCRC()
  {
    // Only necessary for audio transport
  }

  public void setHardwareHandshaking(boolean state) throws SerialPortException
  {
    _hardware = state;
    if (state)
      port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN | SerialPort.FLOWCONTROL_RTSCTS_OUT);
    else
      port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
  }

  public String getInstructionsDone(String guiString)
  {
    Log.println(false, "SerialTransport.getInstructionsDone() getting instructions for: " + guiString);
    String ret = "";
    if ((guiString.equals(Messages.getString("Gui.BS.ProDOSFast")))
        || (guiString.equals(Messages.getString("Gui.BS.ProDOSVSDrive"))))
    {
      _parent.setSerialSpeed(115200);
      // ret = Messages.getString("Gui.BS.DumpProDOSFastInstructionsDone");
    }
    else
      if (guiString.equals(Messages.getString("Gui.BS.ProDOS")))
      {
        ret = Messages.getString("Gui.BS.DumpProDOSInstructionsDone");
      }
      else
        if (guiString.equals(Messages.getString("Gui.BS.ProDOS2")))
        {
          ret = Messages.getString("Gui.BS.DumpProDOSInstructions2Done");
        }
        else
          if (guiString.equals(Messages.getString("Gui.BS.DOS")))
          {
            ret = Messages.getString("Gui.BS.DumpDOSInstructionsDone");
          }
          else
            if (guiString.equals(Messages.getString("Gui.BS.SOS")))
            {
              // _parent.setSerialSpeed(9600);
              /* ret = Messages.getString("Gui.BS.DumpSOSInstructionsDone"); */
            }
    Log.println(false, "SerialTransport.getInstructionsDone() returning: " + ret);
    return ret;
  }

  public String getInstructions(String guiString, int fileSize, int speed)
  {
    String ret = "'SerialTransport.getInstructions() - returned null!'";
    if (guiString.equals(Messages.getString("Gui.BS.ProDOSFast")))
      ret = Messages.getString("Gui.BS.DumpProDOSFastInstructions");
    else
      if (guiString.equals(Messages.getString("Gui.BS.ProDOSVSDrive")))
        ret = Messages.getString("Gui.BS.DumpProDOSVSDriveInstructions");
      else
        if (guiString.equals(Messages.getString("Gui.BS.ProDOS")))
          ret = Messages.getString("Gui.BS.DumpProDOSInstructions");
        else
          if (guiString.equals(Messages.getString("Gui.BS.ProDOS2")))
            ret = Messages.getString("Gui.BS.DumpProDOSInstructions2");
          else
            if (guiString.equals(Messages.getString("Gui.BS.DOS")))
              ret = Messages.getString("Gui.BS.DumpDOSInstructions");
            else
              if (guiString.equals(Messages.getString("Gui.BS.SOS")))
                ret = Messages.getString("Gui.BS.DumpSOSInstructions");
              else
                if (guiString.equals(Messages.getString("Gui.BS.ADT")))
                  ret = Messages.getString("Gui.BS.DumpADTInstructions");
                else
                  if (guiString.equals(Messages.getString("Gui.BS.ADTPro")))
                    ret = Messages.getString("Gui.BS.DumpProInstructions");
                  else
                    if (guiString.equals(Messages.getString("Gui.BS.ADTProAudio")))
                      ret = Messages.getString("Gui.BS.DumpProAudioSerialInstructions");
                    else
                      if (guiString.equals(Messages.getString("Gui.BS.ADTProEthernet")))
                        ret = Messages.getString("Gui.BS.DumpProEthernetInstructions");
    String baudCommand;
    switch (speed)
    {
      case 300:
        baudCommand = "6";
        break;
      case 600:
        baudCommand = "7";
        break;
      case 1200:
        baudCommand = "8";
        break;
      case 1800:
        baudCommand = "9";
        break;
      case 2400:
        baudCommand = "10";
        break;
      case 3600:
        baudCommand = "11";
        break;
      case 4800:
        baudCommand = "12";
        break;
      case 7200:
        baudCommand = "13";
        break;
      case 9600:
        baudCommand = "14";
        break;
      case 19200:
        baudCommand = "15";
        break;
      default:
        baudCommand = "6";
    }
    ret = StringUtilities.replaceSubstring(ret, "%1%", baudCommand);

    Log.println(false, "SerialTransport.getInstructions() returning:\n" + ret);
    return ret;
  }
}
