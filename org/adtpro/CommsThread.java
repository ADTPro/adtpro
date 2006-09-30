/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006 by David Schmidt
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

package org.adtpro;

import java.io.*;
import java.net.SocketException;
import java.util.GregorianCalendar;

import org.adtpro.resources.Messages;
import org.adtpro.transport.ATransport;
import org.adtpro.transport.SerialTransport;
import org.adtpro.transport.UDPTransport;

import org.adtpro.disk.Disk;
import org.adtpro.gui.Gui;
import org.adtpro.utilities.UnsignedByte;

public class CommsThread extends Thread
{
  private boolean _shouldRun = true;

  private ATransport _transport;

  private Gui _parent;

  private static final byte ACK = 0x06, NAK = 0x15;

  private int[] CRCTABLE = new int[256];

  private int _maxRetries = 3;

  GregorianCalendar _startTime = null,
                    _endTime = null;

  private float _diffMillis;

  public CommsThread(Gui parent, String one, String two)
  {
    // System.out.println("CommsThread constructor.");
    _parent = parent;
    try
    {
      if (one.equals(Messages.getString("Gui.Ethernet")))
      {
        _transport = (ATransport)new UDPTransport("6502");
        _transport.open();
      }
      else
        _transport = (ATransport)new SerialTransport(one, two);
    }
    catch (Exception ex)
    {
      System.out.println("CommsThread constructor exception: "+ex);
      _shouldRun = false;
    }
  }

  public void run()
  {
    if (_shouldRun)
    {
      makeCrcTable();
      commandLoop();
    }
    else
      _parent.cancelCommsThread();
  }

  public void commandLoop()
  {
    byte oneByte = (byte) 0x00;
    while (_shouldRun)
    {
      // System.out.println("DEBUG: CommsThread.commandLoop() Waiting for command from Apple: "); //$NON-NLS-1$
      oneByte = waitForData();
      if (_shouldRun)
      {
      // System.out.println("DEBUG: CommsThread.commandLoop() Received a byte."); //$NON-NLS-1$
      _parent.setProgressMaximum(0);
      switch (oneByte)
      {
        case (byte) 195: // CD
          _parent.setMainText(Messages.getString("CommsThread.2")); //$NON-NLS-1$
          _parent.setSecondaryText(""); //$NON-NLS-1$
          // System.out.println("CD..."); //$NON-NLS-1$
          changeDirectory();
          _parent.setSecondaryText(_parent.getWorkingDirectory()); //$NON-NLS-1$
          break;
        case (byte) 196: // DIR
          _parent.setMainText(Messages.getString("CommsThread.1")); //$NON-NLS-1$
          _parent.setSecondaryText(_parent.getWorkingDirectory()); //$NON-NLS-1$
          // System.out.println("Dir..."); //$NON-NLS-1$
          sendDirectory();
          _parent.setSecondaryText(_parent.getWorkingDirectory()); //$NON-NLS-1$
          break;
        case (byte) 208: // Put (Send)
          _parent.setMainText(Messages.getString("CommsThread.16")); //$NON-NLS-1$
          _parent.setSecondaryText(""); //$NON-NLS-1$
          // System.out.println("Put/Send..."); //$NON-NLS-1$
          receiveDisk();
          break;
        case (byte) 199: // Get (Receive)
          _parent.setMainText(Messages.getString("CommsThread.3")); //$NON-NLS-1$
          _parent.setSecondaryText(""); //$NON-NLS-1$
          // System.out.println("Get/Receive..."); //$NON-NLS-1$
          sendDisk();
          break;
        case (byte) 218: // Size
          _parent.setMainText(Messages.getString("CommsThread.14")); //$NON-NLS-1$
          _parent.setSecondaryText(""); //$NON-NLS-1$
          // System.out.println("queryFileSize..."); //$NON-NLS-1$
          queryFileSize();
          break;
        case (byte) 210: // Receive (Legacy ADT style)
          _parent.setMainText(Messages.getString("CommsThread.11")); //$NON-NLS-1$
          _parent.setSecondaryText(""); //$NON-NLS-1$
          // System.out.println("Legacy receive..."); //$NON-NLS-1$
          send140kDisk();
          break;
        case (byte) 211: // Send (Legacy ADT style)
          _parent.setMainText(Messages.getString("CommsThread.15")); //$NON-NLS-1$
          _parent.setSecondaryText(""); //$NON-NLS-1$
          // System.out.println("Legacy send..."); //$NON-NLS-1$
          receive140kDisk();
          break;
        default:
          // System.out.println("not understood... received: " +
          // UnsignedByte.toString(oneByte));
          break;
      }
      }
    }
  }

  public void sendDirectory()
  {
    int i, j, line;
    try
    {
      _transport.writeBytes("DIRECTORY OF "); //$NON-NLS-1$
      _transport.writeBytes(_parent.getWorkingDirectory());
      if (((_parent.getWorkingDirectory().length() + 13) % 40) != 0) _transport.writeByte('\r');
      // 40 dashes separates the wheat from the chaff
      _transport.writeBytes("----------------------------------------"); //$NON-NLS-1$

      File[] files = _parent.getFiles();
      if (files.length > 0)
      {
        i = 0;
        j = 0;
        line = (_parent.getWorkingDirectory().length() + 13) / 40 + 2;
        while (_shouldRun)
        {
          if ((i > 0) && (i + files[j].getName().length() > 40))
          {
            while (i++ < 40)
              _transport.writeByte(' ');
            i = 0;
            line++;
          }
          if (line > 20)
          {
            line = 0;
            _transport.writeByte('\0');
            _transport.writeByte('\1');
            _transport.pushBuffer();
            if (waitForData() == '\0') break;
          }
          line += (files[j].getName().length() / 40);
          i += (files[j].getName().length() % 40);
          _transport.writeBytes(files[j].getName());
          j++;
          if (j + 1 > files.length)
          {
            break;
          }
          do
          {
            if (i == 40)
            {
              i = 0;
              line++;
              break;
            }
            _transport.writeByte(' ');
          }
          while ((++i % 14) > 0);
        }
        _transport.pushBuffer();
      }
      else
        _transport.writeBytes("NO FILES"); //$NON-NLS-1$
      _transport.writeByte('\0');
      _transport.writeByte('\0');
      _transport.pushBuffer();
    }
    catch (Throwable t1)
    {
      System.out.println("sendDirectory exception:"); //$NON-NLS-1$
      System.out.println(t1);
      _transport.writeBytes("NO FILES"); //$NON-NLS-1$
      _transport.writeByte('\0');
      _transport.writeByte('\0');
      _transport.pushBuffer();
    }
  }

  public void queryFileSize()
  {
    long length = 0;
    byte sizeLo = 0, sizeHi = 0, rc = (byte) 0xff;
    String requestedFileName = receiveName();
    Disk disk = null;

    try
    {
      disk = new Disk(_parent.getWorkingDirectory() + File.separator + requestedFileName);
      // System.out.println("queryFileSize found file " +
      // _parent.getWorkingDirectory() + File.separator + requestedFileName);
      // //$NON-NLS-1$
    }
    catch (IOException e)
    {
      try
      {
        disk = new Disk(requestedFileName);
        // System.out.println("queryFileSize found file " + requestedFileName);
        // //$NON-NLS-1$
      }
      catch (IOException e2)
      {
        // System.out.println("can't read file: " + requestedFileName + ".");
        // //$NON-NLS-1$ //$NON-NLS-2$
        rc = 0x02; // Unable to open file
      }
    }
    if (disk == null) rc = 0x02; // Unable to open file
    else
      if (disk.getImageOrder() == null) rc = 0x04; // Unrecognized file format
      else
      {
        length = disk.getImageOrder().getBlocksOnDevice();
        sizeLo = UnsignedByte.loByte(length);
        // System.out.println("loByte of " + requestedFileName + " is: " +
        // UnsignedByte.intValue(sizeLo)); //$NON-NLS-1$ //$NON-NLS-2$
        sizeHi = UnsignedByte.hiByte(length);
        // System.out.println("hiByte of " + requestedFileName + " is: " +
        // UnsignedByte.intValue(sizeHi)); //$NON-NLS-1$ //$NON-NLS-2$
        rc = 0;
      }

    if (disk != null) _parent.setSecondaryText(disk.getFilename());
    else
      _parent.setSecondaryText(requestedFileName);
    // System.out.println("queryFileSize lo:" + UnsignedByte.toString(sizeLo) +
    // " hi:" + UnsignedByte.toString(sizeHi)); //$NON-NLS-1$ //$NON-NLS-2$
    _transport.writeByte(sizeLo);
    _transport.writeByte(sizeHi);
    _transport.writeByte(rc);
    _transport.pushBuffer();
  }

  public void changeDirectory()
  {
    byte rc = 0x06;

    String requestedDirectory = receiveName();
    if (_shouldRun)
    {
      rc = _parent.setWorkingDirectory(requestedDirectory);
      _transport.writeByte(rc);
      _transport.pushBuffer();
    }
  }

  public void receiveDisk()
  /* Main receive routine - Host <- Apple (Apple sends) */
  {
    _startTime = new GregorianCalendar();
    // System.out.print("Waiting for name..."); //$NON-NLS-1$
    String name = _parent.getWorkingDirectory() + File.separator + receiveName();
    // System.out.println(" received name: " + name); //$NON-NLS-1$
    File f = new File(name);
    FileOutputStream fos = null;
    byte[] buffer = new byte[20480];
    int part, length;
    byte report, sizelo, sizehi;
    boolean receiveSuccess = false;
    int halfBlock;
    int blocksDone = 0;

    // New ADT protcol - file size to expect
    // System.out.print("Waiting for sizeLo..."); //$NON-NLS-1$
    sizelo = waitForData();
    // System.out.println(" received sizeLo: " + UnsignedByte.intValue(sizelo));
    // //$NON-NLS-1$
    // System.out.print("Waiting for sizeHi..."); //$NON-NLS-1$
    sizehi = waitForData();
    // System.out.println(" received sizeHi: " + UnsignedByte.intValue(sizehi));
    // //$NON-NLS-1$
    length = UnsignedByte.intValue(sizelo, sizehi);
    _parent.setProgressMaximum(length);
    try
    {
      fos = new FileOutputStream(f);
      // ready for transfer
      _transport.writeByte(0x00);
      _transport.pushBuffer();
      if (waitForData() == ACK)
      {
        _parent.setProgressMaximum((int) length * 2); // Half-blocks
        _parent.setSecondaryText(name);
        int numParts = (int) length / 40;
        int remainder = (int) length % 40;
        for (part = 0; part < numParts; part++)
        {
          //System.out.print("Receiving part " + (part + 1) + " of " + numParts + "; "); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
          for (halfBlock = 0; halfBlock < 80; halfBlock++)
          {
            receiveSuccess = receivePacket(buffer, halfBlock * 256);
            if (!receiveSuccess) break;
            blocksDone++;
            _parent.setProgressValue(blocksDone);
          }
          if (receiveSuccess)
          {
            // System.out.println("Writing part " + (part + 1) + " of " +
            // numParts + "."); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
            fos.write(buffer);
          }
        }
        if ((numParts == 0) && (remainder > 0))
        {
          // Seed the system in case we have a really short device
          // System.out.println("Really short device, so we're setting
          // receiveSuccess to true..."); //$NON-NLS-1$
          receiveSuccess = true;
        }
        if (receiveSuccess && (remainder > 0))
        {
          // System.out.println(" ... read " + charsRead + " chars.");
          // System.out.println("Receiving remainder part."); //$NON-NLS-1$
          for (halfBlock = 0; halfBlock < (remainder * 2); halfBlock++)
          {
            receiveSuccess = receivePacket(buffer, halfBlock * 256);
            if (!receiveSuccess) break;
            blocksDone++;
            _parent.setProgressValue(blocksDone);
          }
          if (receiveSuccess)
          {
            // System.out.println("Writing remainder " + remainder + "
            // blocks."); //$NON-NLS-1$ //$NON-NLS-2$
            fos.write(buffer, 0, remainder * 512);
          }
          else
            System.out.println(" Didn't have luck receiving packets."); //$NON-NLS-1$
        }
        // else
        // System.out.println("Decided not to do a remainder."); //$NON-NLS-1$
        fos.close();
        // System.out.println("Hrm, not getting an ACK from the Apple...");
      }
      else
      {
        receiveSuccess = false;
      }
      if (receiveSuccess)
      {        
        report = waitForData();
        _endTime = new GregorianCalendar();
        _diffMillis = (float)(_endTime.getTimeInMillis() - _startTime.getTimeInMillis())/(float)1000;
        if (report == 0x00)
        {
          _parent.setSecondaryText(Messages.getString("CommsThread.19") + " in " + _diffMillis + " seconds.");
          System.out.println("Apple sent disk image " + name + " successfully in "+(float)(_endTime.getTimeInMillis() - _startTime.getTimeInMillis())/(float)1000+" seconds.");
        }
        else
        {
          _parent.setSecondaryText(Messages.getString("CommsThread.20") + " in " + _diffMillis + " seconds.");
          System.out.println("Apple sent disk image " + name + " with errors."); //$NON-NLS-1$ //$NON-NLS-2$
        }
      }
      else
        _parent.setSecondaryText(Messages.getString("CommsThread.21"));
    }
    catch (FileNotFoundException ex)
    {
      _transport.writeByte(0x02); // New ADT protocol: HMFIL - unable to write file
      _transport.pushBuffer();
    }
    catch (IOException ex2)
    {
      _transport.writeByte(0x02); // New ADT protocol: HMFIL - unable to write file
      _transport.pushBuffer();
    }
    finally
    {
      if (fos != null)
      try
      {
        fos.close();
      }
      catch (IOException io) {}
    }
  }

  public void sendDisk()
  /* Main send routine - Host -> Apple (Host sends) */
  {
    byte[] buffer = new byte[Disk.BLOCK_SIZE];
    int halfBlock, blocksDone = 0;
    byte ack, report;
    int length;
    boolean sendSuccess = false;
    _startTime = new GregorianCalendar();
    /*
     * ADT protocol: receive the requested file name
     */
    String name = receiveName();

    Disk disk = null;
    try
    {
      disk = new Disk(_parent.getWorkingDirectory() + File.separator + name);
    }
    catch (IOException io)
    {
      try
      {
        disk = new Disk(name);
      }
      catch (IOException io2)
      {}
    }
    if (disk != null)
    {
      if (disk.getImageOrder() != null)
      {
        // If the file exists, then...
        _transport.writeByte(0x00); // Tell Apple ][ we're ready to go
        _transport.pushBuffer();
        ack = waitForData();
        // System.out.println("Received initial reply from Apple: " + ack);
        // //$NON-NLS-1$
        if (ack == 0x06)
        {
          length = disk.getImageOrder().getBlocksOnDevice();
          _parent.setProgressMaximum(length * 2); // Half-blocks
          _parent.setSecondaryText(disk.getFilename());
          // System.out.println("Length is " + length + " blocks.");
          // //$NON-NLS-1$ //$NON-NLS-2$
          for (int block = 0; block < length; block++)
          {
            buffer = disk.readBlock(block);
            for (halfBlock = 0; halfBlock < 2; halfBlock++)
            {
              sendSuccess = sendPacket(buffer, halfBlock * 256);
              if (sendSuccess)
              {
                blocksDone++;
                _parent.setProgressValue(blocksDone);
              }
              else
                break;
            }
            if (!sendSuccess) break;
          }
          if (sendSuccess)
          {
            report = waitForData();
            _endTime = new GregorianCalendar();
            _diffMillis = (float)(_endTime.getTimeInMillis() - _startTime.getTimeInMillis())/(float)1000;
            if (report == 0x00)
            {
              _parent.setSecondaryText(Messages.getString("CommsThread.17") + " in " + _diffMillis + " seconds.");
              System.out.println("Apple received disk image " + name + " successfully in "+(float)(_endTime.getTimeInMillis() - _startTime.getTimeInMillis())/(float)1000+" seconds."); //$NON-NLS-1$ //$NON-NLS-2$
            }
            else
            {
              _parent.setSecondaryText(Messages.getString("CommsThread.18"));
              System.out.println("Apple received disk image " + name + " with " + report + " errors."); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
            }
          }
          else
          {
            _parent.setSecondaryText(Messages.getString("CommsThread.21"));
            _parent.clearProgress();
          }
        }
        else
        {
          // System.out.print("No ACK received from the Apple...");
          // //$NON-NLS-1$
          _parent.setSecondaryText(Messages.getString("CommsThread.21"));
          _parent.clearProgress();
        }
      }
      else
      {
        // New ADT protocol: HMFIL - can't open the file
        _transport.writeByte(0x02);
        _transport.pushBuffer();
      }
    }
    else
    {
      // New ADT protocol: HMFIL - can't open the file
      _transport.writeByte(0x02);
      _transport.pushBuffer();
    }
  }

  /**
   * send140kDisk - legacy ADT protocol send 140k disk function
   * 
   * Note these images will be coming in and going out in DOS order.
   */
  public void send140kDisk()
  {
    _startTime = new GregorianCalendar();
    /*
     * ADT protocol: receive the requested file name
     */
    String name = receiveName();
    byte ack;
    int bufSize = 28672;
    byte[] buffer = new byte[bufSize];
    File f = new File(name);
    int rc = 0;
    int sectorsDone = 0;
    FileInputStream fis = null;
    boolean sendSuccess = false;

    if (!f.isFile())
    {
      f = new File(_parent.getWorkingDirectory() + File.separator + name);
      if (!f.isFile())
      {
        _transport.writeByte(26); // ADT protocol - can't open
        _transport.pushBuffer();
        rc = -1;
      }
    }
    if (rc == 0)
    {
      long length = f.length();
      if (length != (long) 143360)
      {
        /*
         * ADT protocol: send error (message) number
         */
        // System.out.println("Not a 140k image"); //$NON-NLS-1$
        _transport.writeByte(30); // ADT protocol - not a 140k image
        _transport.pushBuffer();
        rc = -1;
      }
      else
      {
        /*
         * ADT protocol: send trigger
         */
        _parent.setSecondaryText(name);
        // If the file exists, is pristine, etc., then...
        _transport.writeByte(0x00);
        _transport.pushBuffer();
        try
        {
          /*
           * ADT protocol: receive acknowledgement for "previous" sector
           */
          ack = waitForData();
          if (ack == 0x06)
          {
            _parent.setProgressMaximum(560); // Sectors
            fis = new FileInputStream(f);
            for (int part = 0; part < 5; part++)
            {
              // System.out.print("Reading track " + track);
              // System.out.println(" ... read " + charsRead + " chars.");
              int charsRead = fis.read(buffer);
              for (int track = 0; track < 7; track++)
              {
                for (int sector = 15; sector >= 0; sector--)
                {
                  // System.out.println("Sending track " + (track + (part * 7))
                  // + " sector " + sector + "."); //$NON-NLS-1$ //$NON-NLS-2$
                  // //$NON-NLS-3$
                  sendSuccess = sendPacket(buffer, (track * 4096 + sector * 256));
                  if (!sendSuccess) break;
                  sectorsDone++;
                  _parent.setProgressValue(sectorsDone);
                }
                if (!sendSuccess) break;
              }
              if (!sendSuccess) break;
            }
            fis.close();
            if (sendSuccess)
            {
              /*
               * ADT protocol: receive final error report
               */
              byte report = waitForData();
              _endTime = new GregorianCalendar();
              _diffMillis = (float)(_endTime.getTimeInMillis() - _startTime.getTimeInMillis())/(float)1000;
              if (report == 0x00)
              {
                _parent.setSecondaryText(Messages.getString("CommsThread.19") + " in " + _diffMillis + " seconds.");
                System.out.println("Apple sent disk image " + name + " successfully in "+(float)(_endTime.getTimeInMillis() - _startTime.getTimeInMillis())/(float)1000+" seconds."); //$NON-NLS-1$ //$NON-NLS-2$
              }
              else
              {
                _parent.setSecondaryText(Messages.getString("CommsThread.20") + " in " + _diffMillis + " seconds.");
                System.out.println("Apple sent disk image " + name + " with errors."); //$NON-NLS-1$ //$NON-NLS-2$
              }
            }
            else
              _parent.setSecondaryText(Messages.getString("CommsThread.21"));
          }
          // else
          // System.out.print("No ACK received from the Apple."); //$NON-NLS-1$
        }
        catch (IOException ex)
        {
          // System.out.print("Disk send aborted."); //$NON-NLS-1$
          _parent.setSecondaryText(Messages.getString("CommsThread.21"));
        }
        finally
        {
          if (fis != null) try
          {
            fis.close();
          }
          catch (IOException io)
          {

          }
        }
      }
    }
  }

  public boolean sendPacket(byte[] buffer, int offset)
  {
    boolean rc = false;

    int byteCount, crc, ok = NAK, currentRetries = 0;
    byte data, prev, newprev;

    // System.out.println("sendPacket entry; offset "+offset+".");
    /*
     * for (byteCount = 0; byteCount < 256;byteCount++) { if (byteCount % 32 ==
     * 0) System.out.println("");
     * System.out.print(UnsignedByte.toString(buffer[byteCount]) + " "); }
     */
    do
    {
      // System.out.print(" top of sendPacket loop.");
      prev = 0;
      for (byteCount = 0; byteCount < 256;)
      {
        newprev = buffer[offset + byteCount];
        data = (byte) (UnsignedByte.intValue(newprev) - UnsignedByte.intValue(prev));
        prev = newprev;
        _transport.writeByte(data);
        _transport.pushBuffer();
        if (UnsignedByte.intValue(data) > 0) byteCount++;
        else
        {
          while ((_shouldRun == true) && byteCount < 256 && buffer[offset + byteCount] == newprev)
          {
            byteCount++;
          }
          _transport.writeByte((byte) (byteCount & 0xFF)); // 256 becomes 0
          _transport.pushBuffer();
        }
        if (!_shouldRun)
        {
          rc = false;
          break;
        }
      }
      if (_shouldRun)
      {
        crc = doCrc(buffer, offset, 256);
        _transport.writeByte((byte) (crc & 0xff));
        _transport.writeByte((byte) (((crc & 0xff00) >> 8) & 0xff));
        _transport.pushBuffer();
        // System.out.println("");
        // System.out.println("Locally calculated CRC: " + (crc & 0xffff));
        // //$NON-NLS-1$
        ok = waitForData();
        // System.out.println("ack from Apple: " + ok);
        if (ok == ACK) rc = true;
        else
          currentRetries++;
      }
    }
    while ((ok != ACK) && (_shouldRun == true) && (currentRetries < _maxRetries));

    return rc;
  }

  public void receive140kDisk()
  {
    _startTime = new GregorianCalendar();
    String name = receiveName();
    File f = new File(name);
    FileOutputStream fos = null;
    byte[] buffer = new byte[28672];
    int i, part, track, sector;
    int sectorsDone = 0;
    byte report;
    boolean receiveSuccess = false;

    if (f.exists())
    {
      _transport.writeByte(0x1c); // ADT protocol - file exists
      _transport.pushBuffer();
    }
    else
    {
      try
      {
        fos = new FileOutputStream(f);
      }
      catch (FileNotFoundException ex)
      {
        // We expect a file not found exception
      }
      if (fos != null)
      {
        _parent.setSecondaryText(name);
        for (i = 0; i < buffer.length; i++)
          buffer[i] = 0x00;
        try
        {
          for (i = 0; i < 7; i++)
            fos.write(buffer);
          fos.close();
          _transport.writeByte(0x00); // File is now ready
          _transport.pushBuffer();
          fos = new FileOutputStream(f);
          while (waitForData() != ACK)
          {
            // TODO: What needs to happen here? Original ADT talked about
            // a bad header message...
            System.out.println("hrm, not getting an ACK from the Apple..."); //$NON-NLS-1$
          }
          _parent.setProgressMaximum(560); // sectors
          for (part = 0; part < 5; part++)
          {
            for (track = 0; track < 7; track++)
            {
              for (sector = 15; sector >= 0; sector--)
              {
                receiveSuccess = receivePacket(buffer, (track * 4096) + (sector * 256));
                // System.out.println("Received track " + ((7 * part) + track) +
                // ", sector " + (15 - sector) + ": " + (receiveSuccess ?
                // "Success." : "Failure."));
                if (!receiveSuccess) break;
                sectorsDone++;
                _parent.setProgressValue(sectorsDone);
              }
            }
            fos.write(buffer);
          }
          fos.close();
          if (receiveSuccess)
          {
            report = waitForData();
            _endTime = new GregorianCalendar();
            _diffMillis = (float)(_endTime.getTimeInMillis() - _startTime.getTimeInMillis())/(float)1000;
            if (report == 0x00)
            {
              _parent.setSecondaryText(Messages.getString("CommsThread.19") + " in " + _diffMillis + " seconds.");
              System.out.println("Apple sent disk image " + name + " successfully in "+(float)(_endTime.getTimeInMillis() - _startTime.getTimeInMillis())/(float)1000+" seconds."); //$NON-NLS-1$ //$NON-NLS-2$
            }
            else
            {
              _parent.setSecondaryText(Messages.getString("CommsThread.20") + " in " + _diffMillis + " seconds.");
              // System.out.println("Received disk image " + name + " with
              // errors."); //$NON-NLS-1$ //$NON-NLS-2$
            }
          }
          else
            _parent.setSecondaryText(Messages.getString("CommsThread.21"));

        }
        catch (IOException ex2)
        {
          _transport.writeByte(0x1a); // ADT protocol - unable to write file
          _transport.pushBuffer();
        }
      }
    }
  }

  public boolean receivePacket(byte[] buffer, int offset)
  // Receive a packet with RLE compression
  {
    int byteCount;
    int received_crc = -1, computed_crc = 0;
    byte data = 0x00, prev, crc1 = 0, crc2 = 0;
    boolean rc = false;

    // System.out.println("receivePacket entry; offset "+offset+".");
    do
    {
      // System.out.print(" top of receivePacket loop.");
      prev = 0;
      for (byteCount = 0; byteCount < 256;)
      {
        data = waitForData();
        if (UnsignedByte.intValue(data) > 0)
        {
          prev += UnsignedByte.intValue(data);
          // if (byteCount % 32 == 0) System.out.println("");
          buffer[offset + byteCount++] = prev;
          // System.out.print(UnsignedByte.toString(buffer[(offset + byteCount)
          // -1]) + " ");
        }
        else
        {
          data = waitForData();
          do
          {
            // if (byteCount % 32 == 0) System.out.println("");
            buffer[offset + byteCount++] = prev;
            // System.out.print(UnsignedByte.toString(buffer[offset + byteCount
            // - 1]) + " ");
          }
          while (_shouldRun && byteCount < 256 && byteCount != UnsignedByte.intValue(data));
        }
        if (!_shouldRun)
        {
          rc = false;
          break;
        }
      }
      if (_shouldRun)
      {
        // System.out.println("");
        // System.out.print("Receiving CRC bytes...");
        crc1 = waitForData();
        crc2 = waitForData();
        received_crc = UnsignedByte.intValue(crc1, crc2);
        computed_crc = doCrc(buffer, offset, 256);
        if (received_crc != computed_crc)
        {
          // System.out.println("Incorrect CRC. Computed: " + computed_crc + "
          // Received: " + received_crc); //$NON-NLS-1$ //$NON-NLS-2$
          _transport.writeByte(NAK);
          _transport.pushBuffer();
        }
        else
        {
          // System.out.println("Correct CRC. Computed: " + computed_crc + "
          // Received: " + received_crc); //$NON-NLS-1$ //$NON-NLS-2$
          rc = true;
        }
      }
    }
    while ((received_crc != computed_crc) && (_shouldRun == true));
    if (_shouldRun)
    {
      _transport.writeByte(ACK);
      _transport.pushBuffer();
    }
    // System.out.println("receivePacket exit.");

    return rc;
  }

  public byte waitForData()
  {
    byte oneByte = 0;
    boolean readYet = false;
    while ((readYet == false) && (_shouldRun == true))
    {
      try
      {
        if (_transport != null)
        {
          oneByte = _transport.readByte();
          readYet = true;
        }
        else
        {
          _shouldRun = false;
        }
      }
      catch (SocketException se)
      {
        _shouldRun = false;
      }
      catch (IOException ex)
      {
        ex.printStackTrace();
      }
      catch (Exception e)
      {
        e.printStackTrace();
      }
    }
    return oneByte;
  }

  public String receiveName()
  {
    byte oneByte;
    StringBuffer buf = new StringBuffer();

    for (int i = 0; i < 256; i++)
    {
      if (!_shouldRun) break;
      oneByte = waitForData();
      if (oneByte != (byte) 0x00)
      {
        buf.append((char) (UnsignedByte.intValue(oneByte) & 0x7f));
      }
      else
        break;
    }
    return new String(buf);
  }

  public int doCrc(byte[] buffer, int offset, int count)
  {
    /* Return the CRC of ptr[0]..ptr[count-1] */
    int crc = 0;
    for (int i = 0; i < count; i++)
    {
      crc = ((crc << 8) & 0xff00) ^ (CRCTABLE[(((crc & 0xff00) >> 8) ^ buffer[offset + i]) & 0xff] & 0xffff);
    }
    return crc;
  }

  void makeCrcTable()
  /* Fill the crctable[] array needed by doCrc */
  {
    int oneByte, bit;
    int crc;

    for (oneByte = 0; oneByte < 256; oneByte++)
    {
      crc = oneByte << 8;
      for (bit = 0; bit < 8; bit++)
      {
        crc = (((crc & 0x8000) != 0) ? (crc << 1) ^ 0x1021 : crc << 1);
      }
      CRCTABLE[oneByte] = crc;
    }
  }

  public void requestStop()
  {
    _shouldRun = false;
    try
    {
      _transport.close();
    }
    catch (Exception ex)
    {
      System.out.println("CommsThread.requestStop() exception: "+ex);
    }
  }
}
