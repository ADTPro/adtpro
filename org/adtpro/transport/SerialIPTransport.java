/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2012 by David Schmidt
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

package org.adtpro.transport;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.ConnectException;
import java.net.InetAddress;
import java.net.Socket;
import java.net.SocketException;

import org.adtpro.resources.Messages;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.StringUtilities;
import org.adtpro.utilities.UnsignedByte;

public class SerialIPTransport extends ATransport
{
	String _host;

	int _port, _inPacketPtr = 0, _inPacketLen = 0, _outPacketPtr = 0;

	Socket _socket = null;
	InetAddress _address = null;
	byte[] _receiveBuffer = null;
	byte[] _sendBuffer = null;

	// static byte _packetNum = 1;

	public SerialIPTransport(String host, String port) throws Exception
	{
		_host = host;
		try
		{
			_port = Integer.parseInt(port);
		}
		catch (NumberFormatException e)
		{
			_port = 1977;
		}
		_sendBuffer = new byte[1500];
	}

	public int transportType()
	{
		return TRANSPORT_TYPE_SERIALIP;
	}

	public byte readByte(int seconds) throws TransportTimeoutException
	{
		// Log.println(false,"SerialIPTransport.readByte() entry; _inPacketPtr = "+_inPacketPtr+"; _inPacketLen = "+_inPacketLen+".");
		if (_receiveBuffer == null)
		{
			Log.println(false, "SerialIPTransport.readByte() needs to pull a buffer; buffer is null.");
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
				throw (new TransportTimeoutException());
			}
		}
		if (_inPacketPtr + 1 > _inPacketLen)
		{
			Log.println(false, "SerialIPTransport.readByte() needs to pull a buffer; we're out of data.");
			try
			{
				pullBuffer(seconds);
			}
			catch (Exception e2)
			{
				throw (new TransportTimeoutException());
			}
		}
		return _receiveBuffer[_inPacketPtr++];
	}

	/**
	 * Closes the UDP port.
	 * 
	 * @exception Exception
	 *                any exception encountered is rethrown.
	 */
	public synchronized void close() throws Exception
	{
		Log.println(false, "SerialIPTransport.close() entry.");
		if (_socket != null)
		{
			_socket.close();
			_socket = null;
			Log.println(true, "SerialIPTransport closed SerialIP port " + _port + "."); //$NON-NLS-1$ //$NON-NLS-2$
		}
		Log.println(false, "SerialIPTransport.close() exit.");
	}

	/**
	 * Opens the SerialIP port.
	 * 
	 * @exception Exception
	 *                any exception encountered is rethrown.
	 */
	public void open() throws Exception
	{
		if (_socket != null)
		{
			return;
		}
		else
		{
			_address = InetAddress.getByName(_host);
			try
			{
				_socket = new Socket(_address, _port);
				_socket.setSoTimeout(15000);
				Log.println(false, "SerialIPTransport opened SerialIP port " + _port + " on host " + _host); //$NON-NLS-1$ //$NON-NLS-2$
			}
			catch (ConnectException ex)
			{
				_socket = null;
				Log.println(true, "SerialIPTransport failed to open SerialIP port " + _port + " on host " + _host); //$NON-NLS-1$ //$NON-NLS-2$
			}
			return;
		}
	}

	/**
	 * Writes an array of bytes into a packet.
	 * 
	 * @param data
	 *            the bytes to be written to the serial port.
	 */
	public void writeBytes(byte data[])
	{
		// Log.println(false,"SerialIPTransport.writeBytes() entry.");
		if ((1499 - _outPacketPtr) < data.length)
			pushBuffer();
		if ((1499 - _outPacketPtr) >= data.length) // Should always be true now...
		{
			// Log.println(false,"SerialIPTransport.writeBytes() writing "+data.length+" bytes into packet starting from "+_outPacketPtr+".");
			if (_outPacketPtr == 0)
			{
				// _packetNum++;
				// Log.println(false,"Setting sequence number to: "+
				// UnsignedByte.intValue(_packetNum));
				// _sendBuffer[_outPacketPtr++] = _packetNum;
			}
			for (int i = 0; i < data.length; i++)
			{
				_sendBuffer[_outPacketPtr++] = data[i];
				// Log.println(false,"  data to buffer: "+data[i]);
			}
		}
		//else
			//Log.println(false,"DEBUG: SerialIPTransport.writeBytes() didn't have room!");
	}

	public void writeBytes(char[] data)
	{
		if ((1499 - _outPacketPtr) >= data.length)
		{
			if (_outPacketPtr == 0)
			{
				// _packetNum++;
				// _sendBuffer[_outPacketPtr++] = _packetNum;
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
		byte data[] = { (byte) datum };
		writeBytes(data);
	}

	public void writeByte(int datum)
	{
		byte data[] = { (byte) datum };
		writeBytes(data);
	}

	public void writeByte(byte datum)
	{
		byte data[] = { datum };
		writeBytes(data);
	}

	public void pushBuffer()
	{
		Log.println(false, "SerialIPTransport.pushBuffer() entry.");
		Log.println(false, "SerialIPTransport.pushBuffer() pushing data:");
		for (int i = 0; i < _outPacketPtr; i++)
		{
			if (((i % 32) == 0) && (i != 0))
				Log.println(false, "");
			Log.print(false, UnsignedByte.toString(_sendBuffer[i]) + " ");
		}
		Log.println(false, "");

		if (_socket != null)
		{
			try
			{
				DataOutputStream out = null;
				out = new DataOutputStream(_socket.getOutputStream());
				out.write(_sendBuffer, 0, _outPacketPtr);
				out.flush();
			}
			catch (SocketException s)
			{
				_socket = null;
			}
			catch (Exception e)
			{
				Log.printStackTrace(e);
			}
		}
		else
		{
			Log.println(false, "SerialIPTransport.pushBuffer() socket not connected.");
		}
		_outPacketPtr = 0;
		Log.println(false, "SerialIPTransport.pushBuffer() exit.");
	}

	public void pullBuffer(int seconds) throws Exception
	{
		Log.println(false, "SerialIPTransport.pullBuffer() entry.");
		int numchars = -1;
		_receiveBuffer = new byte[1500];

		if (_socket == null)
			open();
		DataInputStream in = new DataInputStream(_socket.getInputStream());

		try
		{
			numchars = in.read(_receiveBuffer, 0, 1500);
		}
		catch (IOException e)
		{
			Log.println(false, "SerialIPTransport.pullBuffer() got an ioexception from the socket read:");
			Log.println(false, e.getMessage());
			throw new TransportTimeoutException("No data");
		}
		Log.println(false, "SerialIPTransport.pullBuffer() received a packet.");
		if (numchars > 0)
		{
			_inPacketLen = numchars;
			_inPacketPtr = 0;
			Log.println(false, "SerialIPTransport.pullBuffer() pulled data:");
			for (int i = 0; i < _inPacketLen; i++)
			{
				if (((i % 32) == 0) && (i != 0))
					Log.println(false, "");
				Log.print(false, UnsignedByte.toString(_receiveBuffer[i]) + " ");
			}
			Log.println(false, "");
		}
		else
		{
			Log.println(false, "SerialIPTransport.pullBuffer() got 0 or -1 from our socket read.");
			if (numchars == -1)
				_socket = null;
			throw new TransportTimeoutException("No data");
		}
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
		return true;
	}

	public void pauseIncorrectCRC()
	{
		// Only necessary for audio transport
	}

	public String getInstructionsDone(String guiString)
	{
		Log.println(false, "SerialTransport.getInstructionsDone() getting instructions for: " + guiString);
		String ret = "";
		if (guiString.equals(Messages.getString("Gui.BS.ProDOSFast")))
		{
			// ret = Messages.getString("Gui.BS.DumpProDOSFastInstructionsDone");
		}
		else if (guiString.equals(Messages.getString("Gui.BS.ProDOS")))
		{
			ret = Messages.getString("Gui.BS.DumpProDOSInstructionsDone");
		}
		else if (guiString.equals(Messages.getString("Gui.BS.ProDOS2")))
		{
			ret = Messages.getString("Gui.BS.DumpProDOSInstructions2Done");
		}
		else if (guiString.equals(Messages.getString("Gui.BS.DOS")))
		{
			ret = Messages.getString("Gui.BS.DumpDOSInstructionsDone");
		}
		else if (guiString.equals(Messages.getString("Gui.BS.SOS")))
		{
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
	    else if (guiString.equals(Messages.getString("Gui.BS.ProDOSVSDrive")))
	    	ret = Messages.getString("Gui.BS.DumpProDOSVSDriveInstructions");
		else if (guiString.equals(Messages.getString("Gui.BS.ProDOS")))
			ret = Messages.getString("Gui.BS.DumpProDOSInstructions");
		else if (guiString.equals(Messages.getString("Gui.BS.ProDOS2")))
			ret = Messages.getString("Gui.BS.DumpProDOSInstructions2");
		else if (guiString.equals(Messages.getString("Gui.BS.DOS")))
			ret = Messages.getString("Gui.BS.DumpDOSInstructions");
		else if (guiString.equals(Messages.getString("Gui.BS.SOS")))
			ret = Messages.getString("Gui.BS.DumpSOSInstructions");
		else if (guiString.equals(Messages.getString("Gui.BS.ADT")))
			ret = Messages.getString("Gui.BS.DumpADTInstructions");
		else if (guiString.equals(Messages.getString("Gui.BS.ADTPro")))
			ret = Messages.getString("Gui.BS.DumpProInstructions");
		else if (guiString.equals(Messages.getString("Gui.BS.ADTProAudio")))
			ret = Messages.getString("Gui.BS.DumpProAudioSerialInstructions");
		else if (guiString.equals(Messages.getString("Gui.BS.ADTProEthernet")))
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
