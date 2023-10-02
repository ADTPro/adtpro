/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 - 2023 by David Schmidt
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

import jssc.SerialPort;
import jssc.SerialPortException;

import org.adtpro.ADTProperties;
import org.adtpro.gui.Gui;
import org.adtpro.resources.Messages;
import org.adtpro.transport.audio.CaptureThread;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.StringUtilities;
import org.adtpro.utilities.UnsignedByte;

public class AudJoyTransport extends ATransport
{
  protected SerialPort port;

  protected boolean connected;

  protected String _portName = null;

  protected int _currentSpeed = 0;

  protected boolean _hardware = false;


	int _inPacketPtr = 0, _inPacketLen = 0, _outPacketPtr = 0, _bigOutPacketPtr = 0;

	byte[] _receiveBuffer = null;

	byte[] _sendBuffer = null;

	protected Gui _parent = null;

	CaptureThread _captureThread = null;

	ADTProperties _properties = null;

	public AudJoyTransport(Gui parent, String portName, String speed, boolean hardware, ADTProperties properties)
	{
    Log.getSingleton();
		_properties = properties;
    Log.println(false, "AudJoyTransport constructor entry.");
    this._portName = portName;
    connected = false;
    _parent = parent;
    _hardware = hardware;
    _currentSpeed = Integer.parseInt(speed);
    _sendBuffer = new byte[32768];
    Log.println(false, "AudJoyTransport constructor exit.");
	}

	public void open() throws Exception
	{
		Log.println(false, "AudJoyTransport.open() entry...");
		int mixerIndex = 0;
		try
		{
			mixerIndex = Integer.parseInt(_properties.getProperty("AudioHardwareIndex", "0"));
		}
		catch (NumberFormatException e)
		{
			/* Leaves mixerIndex at zero */
		}
		_captureThread = new CaptureThread(mixerIndex);
		_captureThread.start();
    open(_portName, _currentSpeed, _hardware);
		Log.println(true, "AudJoyTransport opened.");
		_sendBuffer = new byte[32768];
		Log.println(false, "AudJoyTransport.open() exit.");
	}

  public void open(String portName, int portSpeed, boolean hardware) throws Exception
  {
    Log.println(false, "AudJoyTransport.open(parms) entry.");
    if (connected)
    {
      Log.println(false, "AudJoyTransport.open() was connected; closing.");
      close();
    }
    port = new SerialPort(portName);
    port.openPort();
    port.setParams(portSpeed, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    setHardwareHandshaking(hardware);
    port.purgePort(SerialPort.PURGE_RXCLEAR | SerialPort.PURGE_TXCLEAR);
    flushReceiveBuffer();
    connected = true;
    Log.println(true, "AudJoyTransport opened port named " + portName + " at speed " + portSpeed + "."); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
    return;
  }

	public int transportType()
	{
		return TRANSPORT_TYPE_AUDJOY;
	}

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

	public void setSlowSpeed(int speed)
	{
    Log.println(false, "AudJoyTransport.setSlowSpeed() setting speed to " + speed);
    try
    {
      port.setParams(speed, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
    }
    catch (SerialPortException e)
    {
      Log.printStackTrace(e);
    }
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

	/**
	 * Writes an array of bytes into a packet.
	 * 
	 * @param data
	 *                the bytes to be written to the serial port.
	 */
	public void writeBytes(byte data[], String log)
	{
		// Log.println(false, "AudJoyTransport.writeBytes() entry.");
    Log.println(false, "AudJoyTransport.writeBytes() adding " + data.length + " bytes to the stream.");
    if (_outPacketPtr + data.length > _sendBuffer.length)
    {
      Log.println(false, "AudJoyTransport.writeBytes() Re-allocating the send buffer: " + _sendBuffer.length
          + " bytes is the new size.");
      byte newBuffer[] = new byte[_sendBuffer.length + data.length];
      for (int i = 0; i < _sendBuffer.length; i++)
        newBuffer[i] = _sendBuffer[i];
      _sendBuffer = new byte[newBuffer.length * 2];
      for (int i = 0; i < newBuffer.length; i++)
        _sendBuffer[i] = newBuffer[i];
      _outPacketPtr = newBuffer.length;
    }
    // Log.println(false, "AudJoyTransport.writeBytes() writing " + data.length
    // + " bytes into packet starting from " + _outPacketPtr + ".");
    for (int i = 0; i < data.length; i++)
    {
      _sendBuffer[_outPacketPtr++] = data[i];
    }
    if (_outPacketPtr > 255)
    {
      Log.println(false, "AudJoyTransport.writeBytes() has " + _outPacketPtr + " bytes to send.");
      flushReceiveBuffer();
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

	public byte readByte(int timeout) throws TransportTimeoutException
	{
		byte retByte = 0;
		// Log.println(false, "AudJoyTransport.readByte() entry; _inPacketPtr = " +
		// _inPacketPtr + "; _inPacketLen = " + _inPacketLen + ".");
		if (_receiveBuffer == null)
		{
			// Log.println(false, "AudJoyTransport.readByte() needs to pull a buffer; buffer is null.");
			try
			{
				pullBuffer(timeout);
			}
			catch (TransportTimeoutException e)
			{
				throw e;
			}
			catch (TransportClosedException e1)
			{
				throw new TransportTimeoutException();
			}
		}
		if (_inPacketPtr + 1 > _inPacketLen)
		{
			// Log.println(false, "AudJoyTransport.readByte() needs to pull a buffer; we're out of data.");
			try
			{
				pullBuffer(timeout);
			}
			catch (TransportTimeoutException e)
			{
				throw e;
			}
			catch (TransportClosedException e1)
			{
				throw new TransportTimeoutException();
			}
		}
		if (_receiveBuffer != null)
		{
			/*
			 * if ((_inPacketPtr <= _receiveBuffer.length) && (_receiveBuffer.length > 0)) { int myByte = _receiveBuffer[_inPacketPtr]; if (myByte < 0) myByte += 256; Log.println(false, "AudJoyTransport.readByte() exit with " + UnsignedByte.toString(UnsignedByte.loByte(myByte))); }
			 */
			if (_receiveBuffer.length > 0)
				retByte = _receiveBuffer[_inPacketPtr++];
			else
				retByte = 0;
		}
		return retByte;
	}

	public void pushBuffer()
	{
		Log.println(false, "AudJoyTransport.pushBuffer() entry, pushing " + _outPacketPtr + " bytes.");
    if (_outPacketPtr > 0)
    {
      if (Log.getSingleton().isLogging())
      {
        // Log the data we're planning to send as a chunk of hex
        Log.println(false, "AudJoyTransport.pushBuffer() pushing data:");
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
        // byte newBuffer[] = new byte[_outPacketPtr];
        for (int i = 0; i < _outPacketPtr; i++)
        {
          Log.println(false, "AudJoyTransport.pushBuffer sending 0x"+UnsignedByte.toString(_sendBuffer[i])+".");
          port.writeByte(_sendBuffer[i]);
          try
          {
            Log.println(false, "AudJoyTransport.pushBuffer sleeping.");
            // Need to pace a bit for our joystick bitbanger
            // It's proven to work ok with sleep (1), but we've also added
            // keyboard (escape key) polling, which takes time too
            Thread.sleep(2);
          }
          catch (InterruptedException e)
          {
            e.printStackTrace();
          }
        }
      }
      catch (SerialPortException e)
      {
        Log.printStackTrace(e);
        e.printStackTrace();
      }
      _outPacketPtr = 0;
    }
		Log.println(false, "AudJoyTransport.pushBuffer() exit.");
	}

	public void pullBuffer(int seconds) throws TransportTimeoutException, TransportClosedException
	{
		Log.println(false, "AudJoyTransport.pullBuffer() entry; timeout = " + seconds + " seconds.");
		int collectedTimeouts = 0;
		while ((_captureThread != null) && ((_captureThread.receiveBufferSize()) == 0) && (collectedTimeouts / 4 < seconds))
		{
			// Log.println(false, "AudJoyTransport.pullBuffer() sleeping... collectedTimeouts: " + collectedTimeouts / 4 + " requested: " + seconds);
			try
			{
				Thread.sleep(250);
			}
			catch (InterruptedException e)
			{

			}
			collectedTimeouts++;
		}
		if (_captureThread != null)
		{
			if (_captureThread.receiveBufferSize() == 0)
			{
				throw new TransportTimeoutException();
			}
			if (_captureThread.receiveBufferSize() > 0)
			{
				_receiveBuffer = _captureThread.retrieveReceiveBuffer();
				_inPacketLen = _receiveBuffer.length;
				_inPacketPtr = 0;
				Log.println(false, "AudJoyTransport.pullBuffer() pulled data:");
				for (int i = 0; i < _inPacketLen; i++)
				{
					if (((i % 32) == 0) && (i != 0))
						Log.println(false, "");
					Log.print(false, UnsignedByte.toString(_receiveBuffer[i]) + " ");
				}
			}
			Log.println(false, "");
		}
		else
			throw new TransportClosedException();
		Log.println(false, "AudJoyTransport.pullBuffer() exit; _inPacketLen = " + _inPacketLen);
	}

	public void flushSendBuffer()
	{
		Log.println(false, "AudJoyTransport.flushSendBuffer() entry.");
		_outPacketPtr = 0;
		Log.println(false, "AudJoyTransport.flushSendBuffer() exit.");
	}

	public void flushReceiveBuffer()
	{
		Log.println(false, "AudJoyTransport.flushReceiveBuffer() entry.");
		if (_captureThread != null)
			_captureThread.flushReceiveBuffer();
		Log.println(false, "AudJoyTransport.flushReceiveBuffer() exit.");
	}

	public void close() throws Exception
	{
		Log.println(false, "AudJoyTransport.close() entry.");
		// Stop the audio capture thread
		if (_captureThread != null)
		{
			_captureThread.requestStop();
			_captureThread = null;
		}
		_sendBuffer = null;
    if (connected)
    {
      connected = false;
      Log.println(false, "AudJoyTransport.close() closing port..."); //$NON-NLS-1$
      port.closePort();
      port = null;
      Log.println(false, "AudJoyTransport.close() closed port."); //$NON-NLS-1$
    }
    else
      Log.println(false, "AudJoyTransport.close() didn't think port was connected."); //$NON-NLS-1$

		Log.println(true, "AudJoyTransport closed.");
		Log.println(false, "AudJoyTransport.close() exit.");
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
			Log.println(false, "AudJoyTransport.pauseIncorrectCRC() Pausing for garbled data...");
			Thread.sleep(7000);
			Log.println(false, "AudJoyTransport.pauseIncorrectCRC() Done pausing.");
		}
		catch (InterruptedException e)
		{
			Log.printStackTrace(e);
		}

	}

  public void setHardwareHandshaking(boolean state) throws SerialPortException
  {
    _hardware = state;
    if (state)
      port.setFlowControlMode(SerialPort.FLOWCONTROL_RTSCTS_IN | SerialPort.FLOWCONTROL_RTSCTS_OUT);
    else
      port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
  }

	public String getInstructions(String guiString, int fileSize, int serialSpeed)
	{
		String ret = "AudJoyTransport.getInstructions() - returned null! looking for: "+guiString+"";
		int endAddr = 0;
		if (guiString.equals(Messages.getString("Gui.BS.ProDOS")))
		{
			ret = Messages.getString("Gui.BS.DumpProDOSAudioInstructions");
			endAddr = fileSize - 1 + 8192;
			String endAddrHex = UnsignedByte.toString(UnsignedByte.hiByte(endAddr)) + UnsignedByte.toString(UnsignedByte.loByte(endAddr));
			ret = StringUtilities.replaceSubstring(ret, "%1%", endAddrHex);
		}
		else if (guiString.equals(Messages.getString("Gui.BS.DOS")))
		{
			ret = Messages.getString("Gui.BS.DumpDOSAudioInstructions");
			endAddr = fileSize - 1 + 976;
			String endAddrHex = UnsignedByte.toString(UnsignedByte.hiByte(endAddr)) + UnsignedByte.toString(UnsignedByte.loByte(endAddr));
			ret = StringUtilities.replaceSubstring(ret, "%1%", endAddrHex);
			ret = StringUtilities.replaceSubstring(ret, "0.0", "0."); // Remove the unsightly leading zero
		}
		else if (guiString.equals(Messages.getString("Gui.BS.ADT")))
		{
			ret = Messages.getString("Gui.BS.DumpADTAudioInstructions");
			endAddr = fileSize - 1 + 2051;
			String endAddrHex = UnsignedByte.toString(UnsignedByte.hiByte(endAddr)) + UnsignedByte.toString(UnsignedByte.loByte(endAddr));
			ret = StringUtilities.replaceSubstring(ret, "%1%", endAddrHex);
		}
		else if (guiString.equals(Messages.getString("Gui.BS.DOS2")))
			ret = Messages.getString("Gui.BS.DumpDOSAudioInstructions2");
		else if ((guiString.equals(Messages.getString("Gui.BS.ADTPro"))) || (guiString.equals(Messages.getString("Gui.BS.ADTProAudio"))) || (guiString.equals(Messages.getString("Gui.BS.ADTProAudJoy"))) || (guiString.equals(Messages.getString("Gui.BS.ADTProEthernet"))))
		{
			if (guiString.equals(Messages.getString("Gui.BS.ADTPro")))
				ret = Messages.getString("Gui.BS.DumpProAudioInstructions");
			else if (guiString.equals(Messages.getString("Gui.BS.ADTProAudio")))
				ret = Messages.getString("Gui.BS.DumpProAudioAudioInstructions");
      else if (guiString.equals(Messages.getString("Gui.BS.ADTProEthernet")))
        ret = Messages.getString("Gui.BS.DumpProEthernetAudioInstructions");
      else if (guiString.equals(Messages.getString("Gui.BS.ADTProAudJoy")))
        ret = Messages.getString("Gui.BS.DumpProAudJoyInstructions");
			endAddr = fileSize - 1 + 2048;
			String endAddrHex = UnsignedByte.toString(UnsignedByte.hiByte(endAddr)) + UnsignedByte.toString(UnsignedByte.loByte(endAddr));
			ret = StringUtilities.replaceSubstring(ret, "%1%", endAddrHex);
		}
		Log.println(false, "AudJoyTransport.getInstructions() returning:\n" + ret);
		return ret;
	}

	public void setAudioParms() throws Exception
	{
		_captureThread.requestStop();
		int mixerHardwareIndex = 0;
		try
		{
			mixerHardwareIndex = Integer.parseInt(_properties.getProperty("AudioHardwareIndex", "0"));
		}
		catch (NumberFormatException e)
		{
			/* Leaves mixerIndex at zero */
		}
		_captureThread = new CaptureThread(mixerHardwareIndex);
		_captureThread.start();
	}

	public String getInstructionsDone(String guiString)
	{
		Log.println(false, "AudJoyTransport.getInstructionsDone() entry for command: " + guiString);
		String ret = "AudJoyTransport.getInstructionsDone() - returned null!";
		if (guiString.equals(Messages.getString("Gui.BS.ProDOS")))
		{
			ret = Messages.getString("Gui.BS.DumpProDOSAudioInstructionsDone");
		}
		else if (guiString.equals(Messages.getString("Gui.BS.ProDOS2")))
			ret = Messages.getString("Gui.BS.DumpProDOSAudioInstructions2Done");
		else if (guiString.equals(Messages.getString("Gui.BS.DOS")))
		{
			ret = Messages.getString("Gui.BS.DumpDOSAudioInstructionsDone");
		}
		else if (guiString.equals(Messages.getString("Gui.BS.DOS2")))
			ret = Messages.getString("Gui.BS.DumpDOSAudioInstructions2Done");
		else if ((guiString.equals(Messages.getString("Gui.BS.ADT"))) || (guiString.equals(Messages.getString("Gui.BS.ADTPro"))) || (guiString.equals(Messages.getString("Gui.BS.ADTProAudio")))  || (guiString.equals(Messages.getString("Gui.BS.ADTProAudJoy"))) || (guiString.equals(Messages.getString("Gui.BS.ADTProEthernet"))))
		{
			if (guiString.equals(Messages.getString("Gui.BS.ADT")))
				ret = Messages.getString("Gui.BS.DumpADTAudioInstructionsDone");
			else if (guiString.equals(Messages.getString("Gui.BS.ADTPro")))
				ret = Messages.getString("Gui.BS.DumpProAudioInstructionsDone");
      else if (guiString.equals(Messages.getString("Gui.BS.ADTProAudio")))
        ret = Messages.getString("Gui.BS.DumpProAudioAudioInstructionsDone");
      else if (guiString.equals(Messages.getString("Gui.BS.ADTProAudJoy")))
        ret = Messages.getString("Gui.BS.DumpProAudJoyInstructionsDone");
			else if (guiString.equals(Messages.getString("Gui.BS.ADTProEthernet")))
				ret = Messages.getString("Gui.BS.DumpProEthernetAudioInstructionsDone");
		}
		Log.println(false, "AudJoyTransport.getInstructionsDone() returning:\n" + ret);
		return ret;
	}
}