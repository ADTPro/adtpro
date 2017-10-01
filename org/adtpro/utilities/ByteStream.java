/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2014 by David Schmidt
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

package org.adtpro.utilities;

public class ByteStream
{
byte[] _buffer;
int _cursor = 0;

	public ByteStream(byte[] buffer)
	{
		_cursor = 0;
		_buffer = buffer;
	}

	public void writeBytes(String str)
	{
		writeBytes(str.getBytes());
	}

	public void writeBytes(byte data[])
	{
		int i;
		for (i = 0; i < data.length; i++)
	          _buffer[_cursor + i] = data[i];
		_cursor += i;
	}

	public void writeByte(char datum)
	{
		byte data[] = { (byte) (datum) };
		writeBytes(data);
	}

	public void writeByte(byte datum)
	{
		byte data[] = { datum };
	    writeBytes(data);
	}

	public byte[] getBuffer()
	{
		return _buffer;
	}
}
