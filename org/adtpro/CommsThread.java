/*
 * Copyright (C) 2006, 2007 by David Schmidt
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
import java.util.GregorianCalendar;

import org.adtpro.resources.Messages;
import org.adtpro.transport.ATransport;
import org.adtpro.transport.AudioTransport;
import org.adtpro.transport.SerialTransport;
import org.adtpro.transport.TransportTimeoutException;
import org.adtpro.transport.UDPTransport;

import org.adtpro.disk.Disk;
import org.adtpro.gui.Gui;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.UnsignedByte;

public class CommsThread extends Thread
{
  private boolean _shouldRun = true;

  private boolean _busy = false;

  protected boolean _client01xCompatibleProtocol = false;

  private ATransport _transport;

  private Gui _parent;

  private static final byte ACK = 0x06, NAK = 0x15;

  private int[] CRCTABLE = new int[256];

  private int _maxRetries = 10;

  GregorianCalendar _startTime = null, _endTime = null;

  private float _diffMillis;

  private Worker _worker = null;

  public CommsThread(Gui parent, ATransport transport)
  {
    _transport = transport;
    Log.getSingleton();
    Log.println(false, "CommsThread constructor entry.");
    _parent = parent;
    try
    {
      _transport.open();
    }
    catch (java.net.BindException ex1)
    {
      Log.printStackTrace(ex1);
      _parent.cancelCommsThread("Gui.PortInUse");
      requestStop();
    }
    catch (gnu.io.PortInUseException ex1)
    {
      Log.printStackTrace(ex1);
      _parent.cancelCommsThread("Gui.PortInUse");
      requestStop();
    }
    catch (gnu.io.NoSuchPortException ex1)
    {
      Log.printStackTrace(ex1);
      requestStop();
      _parent.cancelCommsThread("Gui.PortDoesNotExist");
    }
    catch (Exception ex)
    {
      Log.printStackTrace(ex);
      _shouldRun = false;
    }
    Log.println(false, "CommsThread constructor exit; _shouldRun=" + _shouldRun);
  }

  public void run()
  {
    Log.println(false, "CommsThread.run() entry; _shouldRun=" + _shouldRun);
    if (_shouldRun)
    {
      makeCrcTable();
      commandLoop();
    }
    else
    {
      if (_transport != null) try
      {
        _transport.close();
      }
      catch (Exception e)
      {
        e.printStackTrace();
      }
    }
    Log.println(false, "CommsThread.run() exit.");
  }

  public void commandLoop()
  {
    Log.println(false, "CommsThread.commandLoop() starting.");
    byte oneByte = (byte) 0x00;
    boolean readYet = false;
    while (_shouldRun)
    {
      Log.println(false, "CommsThread.commandLoop() Waiting for command from Apple."); //$NON-NLS-1$
      readYet = false;
      _busy = false;
      while (_shouldRun && !readYet)
        try
        {
          oneByte = waitForData(1);
          readYet = true;
          Log.println(false, "CommsThread.commandLoop() Received data."); //$NON-NLS-1$
        }
        catch (TransportTimeoutException e)
        {
          Log.println(false, "CommsThread.commandLoop() Timeout in command..."); //$NON-NLS-1$
        }
      if (_shouldRun)
      {
        Log.println(false, "CommsThread.commandLoop() Received a byte: " + UnsignedByte.toString(oneByte)); //$NON-NLS-1$
        _parent.setProgressMaximum(0);
        switch (oneByte)
        {
          case (byte) 195: // "C": CD
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.2")); //$NON-NLS-1$
            _parent.setSecondaryText(""); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received CD command."); //$NON-NLS-1$
            changeDirectory();
            _parent.setSecondaryText(_parent.getWorkingDirectory()); //$NON-NLS-1$
            _busy = false;
            break;
          case (byte) 196: // "D": DIR
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.1")); //$NON-NLS-1$
            _parent.setSecondaryText(_parent.getWorkingDirectory()); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received DIR command."); //$NON-NLS-1$
            sendDirectory();
            _parent.setSecondaryText(_parent.getWorkingDirectory()); //$NON-NLS-1$
            _busy = false;
            break;
          case (byte) 208: // "P": Put (Send)
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.16")); //$NON-NLS-1$
            _parent.setSecondaryText(""); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received Put/Send command."); //$NON-NLS-1$
            receiveDisk(false);
            _busy = false;
            break;
          case (byte) 199: // "G": Get (Receive)
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.3")); //$NON-NLS-1$
            _parent.setSecondaryText(""); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received Get/Receive command."); //$NON-NLS-1$
            sendDisk();
            _busy = false;
            break;
          case (byte) 194: // "B": Batch send
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.3")); //$NON-NLS-1$
            _parent.setSecondaryText(""); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received Batch command."); //$NON-NLS-1$
            receiveDisk(true);
            _busy = false;
            break;
          case (byte) 217: // "Y": Ping
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.23")); //$NON-NLS-1$
            _parent.setSecondaryText(""); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received Ping command."); //$NON-NLS-1$
            _transport.pushBuffer();
            _transport.flushReceiveBuffer();
            _busy = false;
            break;
          case (byte) 218: // "Q": Size
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.14")); //$NON-NLS-1$
            _parent.setSecondaryText(""); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received Query File Size command."); //$NON-NLS-1$
            queryFileSize();
            _busy = false;
            break;
          case (byte) 210: // "R": Receive (Legacy ADT style)
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.11")); //$NON-NLS-1$
            _parent.setSecondaryText(""); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received ADT Receive command."); //$NON-NLS-1$
            send140kDisk();
            _busy = false;
            break;
          case (byte) 211: // "S": Send (Legacy ADT style)
            _busy = true;
            _parent.setMainText(Messages.getString("CommsThread.15")); //$NON-NLS-1$
            _parent.setSecondaryText(""); //$NON-NLS-1$
            Log.println(false, "CommsThread.commandLoop() Received ADT Send command."); //$NON-NLS-1$
            receive140kDisk();
            _busy = false;
            break;
          default:
            Log.println(false, "CommsThread.commandLoop() Received unknown command: " + UnsignedByte.toString(oneByte)); //$NON-NLS-1$
            break;
        }
      }
    }
    Log.println(false, "CommsThread.commandLoop() ending."); //$NON-NLS-1$
  }

  public void sendDirectory()
  {
    int i, j, line;
    Log.println(false, "CommsThread.sendDirectory() Seeking directory of: " + _parent.getWorkingDirectory());
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
            if (waitForData(15) == '\0') break;
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
      }
      else
        _transport.writeBytes("NO FILES"); //$NON-NLS-1$
      _transport.writeByte('\0');
      _transport.writeByte('\0');
      _transport.pushBuffer();
    }
    catch (Throwable t1)
    {
      Log.println(true, "sendDirectory exception:"); //$NON-NLS-1$
      Log.printStackTrace(t1);
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
    try
    {
      String requestedFileName = receiveName();
      Disk disk = null;
      try
      {
        Log.println(false, "CommsThread.queryFileSize() seeking file " + _parent.getWorkingDirectory()
            + requestedFileName);
        disk = new Disk(_parent.getWorkingDirectory() + requestedFileName);
      }
      catch (IOException e)
      {
        try
        {
          Log.println(false, "CommsThread.queryFileSize() failed to find that file.");
          Log.println(false, "CommsThread.queryFileSize() seeking file " + requestedFileName); //$NON-NLS-1$
          disk = new Disk(requestedFileName);
          Log.println(false, "CommsThread.queryFileSize() found file " + requestedFileName); //$NON-NLS-1$
        }
        catch (IOException e2)
        {
          Log.println(false, "CommsThread.queryFileSize() can't read file: " + requestedFileName + "."); //$NON-NLS-1$ //$NON-NLS-2$
          rc = 0x02; // Unable to open file
        }
      }
      catch (ArrayIndexOutOfBoundsException ix)
      {
        rc = 0x04; // Unrecognized file format
      }
      if (disk == null)
      {
        if (rc == (byte) 0xff) rc = 0x02; // Unable to open file
        // else let rc be whatever it was before
      }
      else
        if (disk.getImageOrder() == null) rc = 0x04; // Unrecognized file
        // format
        else
        {
          length = disk.getImageOrder().getBlocksOnDevice();
          sizeLo = UnsignedByte.loByte(length);
          sizeHi = UnsignedByte.hiByte(length);
          rc = 0;
        }

      if (disk != null) _parent.setSecondaryText(disk.getFilename());
      else
        _parent.setSecondaryText(requestedFileName);
      Log.println(false,
          "CommsThread.queryFileSize() lo:" + UnsignedByte.toString(sizeLo) + " hi:" + UnsignedByte.toString(sizeHi)); //$NON-NLS-1$ //$NON-NLS-2$
      _transport.writeByte(sizeLo);
      _transport.writeByte(sizeHi);
      _transport.writeByte(rc);
      _transport.pushBuffer();
    }
    catch (TransportTimeoutException e)
    {
      Log.println(false, "CommsThread.queryFileSize() aborting due to timeout.");
    }
  }

  public void changeDirectory()
  {
    byte rc = 0x06;

    try
    {
      String requestedDirectory = receiveName();
      if (_shouldRun)
      {
        rc = _parent.setWorkingDirectory(requestedDirectory);
        _transport.writeByte(rc);
        _transport.pushBuffer();
      }
    }
    catch (TransportTimeoutException e)
    {
      Log.println(false, "CommsThread.changeDirectory() aborting due to timeout.");
      _parent.setSecondaryText(Messages.getString("CommsThread.21"));
    }
  }

  public void receiveDisk(boolean generateName)
  /* Main receive routine - Host <- Apple (Apple sends) */
  {
    Log.println(false, "CommsThread.receiveDisk() entry.");
    _startTime = new GregorianCalendar();
    try
    {
      Log.print(false, "Waiting for name..."); //$NON-NLS-1$
      String name = _parent.getWorkingDirectory() + receiveName();
      Log.println(false, " received name: " + name); //$NON-NLS-1$
      File f = null;
      String nameGen, zeroPad;
      if (generateName)
      {
        do
        {
          if (lastFileNumber < 10) zeroPad = "000";
          else
            if (lastFileNumber < 100) zeroPad = "00";
            else
              if (lastFileNumber < 1000) zeroPad = "0";
              else
                zeroPad = "";
          nameGen = zeroPad + lastFileNumber;
          f = new File(name + nameGen + ".PO");
          lastFileNumber++;
        }
        while (f.exists());
        name = name + nameGen + ".PO";
      }
      else
        f = new File(name);
      FileOutputStream fos = null;
      byte[] buffer = new byte[20480];
      int part, length, packetResult = 0;
      byte report, sizelo, sizehi;
      int halfBlock;
      int blocksDone = 0;

      // New ADT protcol - file size to expect
      Log.println(false, "Waiting for sizeLo..."); //$NON-NLS-1$

      sizelo = waitForData(15);
      Log.println(false, " received sizeLo: " + UnsignedByte.toString(sizelo)); //$NON-NLS-1$
      Log.println(false, "Waiting for sizeHi..."); //$NON-NLS-1$
      sizehi = waitForData(15);
      Log.println(false, " received sizeHi: " + UnsignedByte.toString(sizehi)); //$NON-NLS-1$
      length = UnsignedByte.intValue(sizelo, sizehi);
      _parent.setProgressMaximum(length);
      try
      {
        fos = new FileOutputStream(f);
        // ready for transfer
        _transport.writeByte(0x00);
        _transport.pushBuffer();
        Log.println(false, "CommsThread.receiveDisk() about to wait for ACK from apple...");
        if (waitForData(15) == ACK)
        {
          Log.println(false, "receiveDisk() received ACK from apple.");
          _parent.setProgressMaximum((int) length * 2); // Half-blocks
          _parent.setSecondaryText(name);
          int numParts = (int) length / 40;
          int remainder = (int) length % 40;
          for (part = 0; part < numParts; part++)
          {
            Log.println(false, "receiveDisk() Receiving part " + (part + 1) + " of " + numParts + "; "); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
            for (halfBlock = 0; halfBlock < 80; halfBlock++)
            {
              packetResult = receivePacket(buffer, halfBlock * 256, (part * 80 + halfBlock), true);
              if (packetResult != 0) break;
              blocksDone++;
              _parent.setProgressValue(blocksDone);
            }
            if (packetResult != 0) break;
            Log.println(false, "Writing part " + (part + 1) + " of " + numParts + "."); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
            fos.write(buffer);
          }
          Log.println(false, "CommsThread.receiveDisk() Bottom of for loop... packetResult: " + packetResult);
          if ((packetResult == 0) && (remainder > 0))
          {
            Log.println(false, "Receiving remainder part."); //$NON-NLS-1$
            for (halfBlock = 0; halfBlock < (remainder * 2); halfBlock++)
            {
              packetResult = receivePacket(buffer, halfBlock * 256, (part * 80 + halfBlock), true);
              if (packetResult == -1) break;
              blocksDone++;
              _parent.setProgressValue(blocksDone);
            }
            if (packetResult == 0)
            {
              Log.println(false, "Writing remainder " + remainder + " blocks."); //$NON-NLS-1$ //$NON-NLS-2$
              fos.write(buffer, 0, remainder * 512);
            }
          }
          fos.close();
          Log.println(false, "CommsThread.receiveDisk() length: "+length+" Disk.APPLE_140KB_DISK: "+Disk.APPLE_140KB_DISK);
          if ((length * 512) == Disk.APPLE_140KB_DISK)
          {
            Disk disk = new Disk(name);
            disk.makeDosOrder();
            disk.save();
            Log.println(false, "CommsThread.receiveDisk() found a 140k disk; saved as DOS order format.");
          }
        }
        else
        {
          packetResult = -1;
        }
        if (packetResult == 0)
        {
          report = waitForData(15);
          _endTime = new GregorianCalendar();
          _diffMillis = (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000;
          if (report == 0x00)
          {
            _parent.setSecondaryText(Messages.getString("CommsThread.19") + " in " + _diffMillis + " seconds.");
            Log.println(true, "Apple sent disk image " + name + " successfully in "
                + (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000 + " seconds.");
          }
          else
          {
            _parent.setSecondaryText(Messages.getString("CommsThread.20") + " in " + _diffMillis + " seconds.");
            Log.println(true, "Apple sent disk image " + name + " with errors."); //$NON-NLS-1$ //$NON-NLS-2$
          }
        }
        else
        {
          Log.println(true, Messages.getString("CommsThread.21"));
          _parent.setSecondaryText(Messages.getString("CommsThread.21"));
          _parent.clearProgress();
          _transport.flushReceiveBuffer();
          _transport.flushSendBuffer();
        }
      }
      catch (FileNotFoundException ex)
      {
        _transport.writeByte(0x02); // New ADT protocol: HMFIL - unable to write
        // file
        _transport.pushBuffer();
      }
      catch (IOException ex2)
      {
        _transport.writeByte(0x02); // New ADT protocol: HMFIL - unable to write
        // file
        _transport.pushBuffer();
      }
      finally
      {
        if (fos != null) try
        {
          fos.close();
        }
        catch (IOException io)
        {}
      }
    }
    catch (TransportTimeoutException e)
    {
      Log.println(false, "CommsThread.receiveDisk() aborting due to timeout.");
      _parent.setSecondaryText(Messages.getString("CommsThread.21"));
    }
    Log.println(false, "CommsThread.receiveDisk() exit.");
  }

  public void sendDisk()
  /* Main send routine - Host -> Apple (Host sends) */
  {
    Log.println(false, "CommsThread.sendDisk() entry.");
    Log.println(false, "Current working directory: " + _parent.getWorkingDirectory());
    byte[] buffer = new byte[Disk.BLOCK_SIZE];
    int halfBlock, blocksDone = 0;
    byte ack, report;
    int length;
    boolean sendSuccess = false;
    _startTime = new GregorianCalendar();
    /*
     * ADT protocol: receive the requested file name
     */
    try
    {
      String name = receiveName();
      Disk disk = null;
      try
      {
        Log.println(false, "CommsThread.sendDisk() looking for file: " + _parent.getWorkingDirectory() + name);
        disk = new Disk(_parent.getWorkingDirectory() + name);
      }
      catch (IOException io)
      {
        try
        {
          Log.println(false, "CommsThread.sendDisk() Failed to find that file.  Now looking for: " + name);
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
          Log.println(false, "CommsThread.sendDisk() about to wait for initial ack.");
          ack = waitForData(15);
          Log.println(false, "CommsThread.sendDisk() received initial reply from Apple: " + UnsignedByte.toString(ack)); //$NON-NLS-1$
          if (ack == 0x06)
          {
            if (_client01xCompatibleProtocol == false)
            {
              waitForData(15);
              waitForData(15);
              waitForData(15);
            }
            length = disk.getImageOrder().getBlocksOnDevice();
            _parent.setProgressMaximum(length * 2); // Half-blocks
            _parent.setSecondaryText(disk.getFilename());
            Log.println(false, "CommsThread.sendDisk() disk length is " + length + " blocks."); //$NON-NLS-1$ //$NON-NLS-2$
            for (int block = 0; block < length; block++)
            {
              buffer = disk.readBlock(block);
              for (halfBlock = 0; halfBlock < 2; halfBlock++)
              {
                Log.println(false, "CommsThread.sendDisk() sending packet for block: " + block + " halfBlock: "
                    + (2 - halfBlock));
                sendSuccess = sendPacket(buffer, block, halfBlock * 256, true);
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
              report = waitForData(15);
              _endTime = new GregorianCalendar();
              _diffMillis = (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000;
              if (report == 0x00)
              {
                _parent.setSecondaryText(Messages.getString("CommsThread.17") + " in " + _diffMillis + " seconds.");
                Log
                    .println(
                        true,
                        "Apple received disk image " + name + " successfully in " + (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000 + " seconds."); //$NON-NLS-1$ //$NON-NLS-2$
              }
              else
              {
                _parent.setSecondaryText(Messages.getString("CommsThread.18"));
                Log.println(true, "Apple received disk image " + name + " with " + report + " errors."); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
              }
            }
            else
            {
              Log.println(true, Messages.getString("CommsThread.21"));
              _parent.setSecondaryText(Messages.getString("CommsThread.21"));
              _parent.clearProgress();
              _transport.flushReceiveBuffer();
              _transport.flushSendBuffer();
            }
          }
          else
          {
            // Log.print(false,"No ACK received from the Apple...");
            // //$NON-NLS-1$
            _parent.setSecondaryText(Messages.getString("CommsThread.21"));
            _parent.clearProgress();
            _transport.flushReceiveBuffer();
            _transport.flushSendBuffer();
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
    catch (TransportTimeoutException e)
    {
      Log.println(false, "CommsThread.sendDisk() aborting due to timeout.");
      _parent.setSecondaryText(Messages.getString("CommsThread.21"));
    }

    Log.println(false, "CommsThread.sendDisk() exit.");
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
    try
    {
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
        f = new File(_parent.getWorkingDirectory() + name);
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
          Log.println(false, "Not a 140k image for legacy ADT."); //$NON-NLS-1$
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
            ack = waitForData(15);
            if (ack == 0x06)
            {
              _parent.setProgressMaximum(560); // Sectors
              fis = new FileInputStream(f);
              for (int part = 0; part < 5; part++)
              {
                int charsRead = fis.read(buffer);
                Log.println(false, " ... read " + charsRead + " chars.");
                for (int track = 0; track < 7; track++)
                {
                  Log.print(false, "Reading track " + track);
                  for (int sector = 15; sector >= 0; sector--)
                  {
                    Log.println(false, "Sending track " + (track + (part * 7)) + " sector " + sector + "."); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
                    sendSuccess = sendPacket(buffer, 0, (track * 4096 + sector * 256), false);
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
                byte report = waitForData(15);
                _endTime = new GregorianCalendar();
                _diffMillis = (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000;
                if (report == 0x00)
                {
                  _parent.setSecondaryText(Messages.getString("CommsThread.19") + " in " + _diffMillis + " seconds.");
                  Log
                      .println(
                          true,
                          "Apple sent disk image " + name + " successfully in " + (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000 + " seconds."); //$NON-NLS-1$ //$NON-NLS-2$
                }
                else
                {
                  _parent.setSecondaryText(Messages.getString("CommsThread.20") + " in " + _diffMillis + " seconds.");
                  Log.println(true, "Apple sent disk image " + name + " with errors."); //$NON-NLS-1$ //$NON-NLS-2$
                }
              }
              else
              {
                _parent.setSecondaryText(Messages.getString("CommsThread.21"));
                _transport.flushReceiveBuffer();
                _transport.flushSendBuffer();
              }
            }
            // else
            // Log.print(false,"No ACK received from the Apple."); //$NON-NLS-1$
          }
          catch (IOException ex)
          {
            // Log.print(false,"Disk send aborted."); //$NON-NLS-1$
            _parent.setSecondaryText(Messages.getString("CommsThread.21"));
            _transport.flushReceiveBuffer();
            _transport.flushSendBuffer();
          }

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
    catch (TransportTimeoutException e)
    {

    }
    Log.println(false, "send140kDisk() exit.");
  }

  public boolean sendPacket(byte[] buffer, int block, int offset, boolean preamble)
  {
    boolean rc = false;

    int byteCount = 0, crc, ok = NAK, currentRetries = 0;
    byte data, prev, newprev;

    Log.println(false, "CommsThread.sendPacket() entry; offset " + offset + ".");
    do
    {
      prev = 0;
      if ((preamble) && (_client01xCompatibleProtocol == false))
      {
        _transport.writeByte(UnsignedByte.loByte(block));
        _transport.writeByte(UnsignedByte.hiByte(block));
        _transport.writeByte(UnsignedByte.loByte(2 - (offset / 256)));
      }
      for (byteCount = 0; byteCount < 256;)
      {
        newprev = buffer[offset + byteCount];
        data = (byte) (UnsignedByte.intValue(newprev) - UnsignedByte.intValue(prev));
        prev = newprev;
        _transport.writeByte(data);
        if (UnsignedByte.intValue(data) > 0) byteCount++;
        else
        {
          while ((_shouldRun == true) && byteCount < 256 && buffer[offset + byteCount] == newprev)
          {
            byteCount++;
          }
          _transport.writeByte((byte) (byteCount & 0xFF)); // 256 becomes 0
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
        Log.println(false, "CommsThread.sendPacket() calculated CRC: " + (crc & 0xffff));
        try
        {
          ok = waitForData(15);
          if ((preamble) && (_client01xCompatibleProtocol == false))
          {
            int incomingBlock = 0;
            incomingBlock = UnsignedByte.intValue(waitForData(15));
            incomingBlock += (UnsignedByte.intValue(waitForData(15)) * 256);
            byte appleHalf = waitForData(15);
            byte hostHalf = UnsignedByte.loByte(2 - (offset / 256));
            Log.println(false, "CommsThread.sendPacket() Host BlockNum: " + block 
                + " Apple BlockNum: " + incomingBlock);
            Log.println(false, "CommsThread.sendPacket() Host lsb: " + UnsignedByte.toString(UnsignedByte.loByte(block))
                + " Apple lsb: " + UnsignedByte.toString(UnsignedByte.loByte(incomingBlock))
                + " Host msb: " + UnsignedByte.toString(UnsignedByte.hiByte(block))
                + " Apple msb: " + UnsignedByte.toString(UnsignedByte.hiByte(incomingBlock))
                + " Host halfNum: " + UnsignedByte.loByte(2 - (offset / 256))
                + " Apple halfNum: " + appleHalf);
            if (ok == NAK)
            {
              if (((block == incomingBlock) && (appleHalf - hostHalf != 0)) || ((block + 1 == incomingBlock))
                  && (appleHalf - hostHalf != 0))
              {
                ok = ACK;
                Log.println(false, "CommsThread.sendPacket() found an old packet; advancing.");
              }
            }
          }
        }
        catch (TransportTimeoutException te)
        {
          Log.println(false, "CommsThread.sendPacket() timeout.");
          ok = NAK;
        }
        Log
            .println(false, "CommsThread.sendPacket() ACK from Apple: "
                + UnsignedByte.toString(UnsignedByte.loByte(ok)));
        if (ok == ACK)
        {
          rc = true;
        }
        else
        {
          _transport.flushReceiveBuffer();
          currentRetries++;
          Log.println(false, "CommsThread.sendPacket() didn't work; will retry #" + currentRetries+".");
          // For audio transport, pause for an increasing amount of time each time we retry.
          // What's that called - progressive backoff/fallback?
          if (_transport.transportType() == ATransport.TRANSPORT_TYPE_AUDIO)
          {
            try
            {
              Log.println(false, "CommsThread.sendPacket() audio backoff sleeping for " + (currentRetries * 2) + " seconds.");
              sleep(currentRetries * 200); // Sleep 2 seconds for each time we have to retry
            }
            catch (InterruptedException e)
            {
              Log.println(false, "CommsThread.sendPacket() audio backoff sleep was interrupted.");
            }
          }
        }
      }
    }
    while ((ok != ACK) && (_shouldRun == true) && (currentRetries < _maxRetries));

    Log.println(false, "CommsThread.sendPacket() exit, rc = " + rc);
    return rc;
  }

  public void receive140kDisk()
  {
    _startTime = new GregorianCalendar();
    try
    {
      String name = _parent.getWorkingDirectory() + receiveName();
      File f = new File(name);
      FileOutputStream fos = null;
      byte[] buffer = new byte[28672];
      int i, part, track, sector, packetResult = -1;
      int sectorsDone = 0;
      byte report;

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
            while (waitForData(15) != ACK)
            {
              // TODO: What needs to happen here? Original ADT talked about
              // a bad header message...
              Log.println(true, "hrm, not getting an ACK from the Apple..."); //$NON-NLS-1$
            }
            _parent.setProgressMaximum(560); // sectors
            for (part = 0; part < 5; part++)
            {
              for (track = 0; track < 7; track++)
              {
                for (sector = 15; sector >= 0; sector--)
                {
                  packetResult = receivePacket(buffer, (track * 4096) + (sector * 256), -1, false);
                  if (packetResult != 0) break;
                  sectorsDone++;
                  _parent.setProgressValue(sectorsDone);
                }
                if (packetResult != 0) break;
              }
              fos.write(buffer);
              if (packetResult != 0) break;
            }
            fos.close();
            Disk disk = new Disk(name);
            disk.save();
            Log.println(false, "CommsThread.receive140kDisk() saved as DOS order format.");
            if (packetResult == 0)
            {
              report = waitForData(15);
              _endTime = new GregorianCalendar();
              _diffMillis = (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000;
              if (report == 0x00)
              {
                _parent.setSecondaryText(Messages.getString("CommsThread.19") + " in " + _diffMillis + " seconds.");
                Log
                    .println(
                        true,
                        "Apple sent disk image " + name + " successfully in " + (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000 + " seconds."); //$NON-NLS-1$ //$NON-NLS-2$
              }
              else
              {
                _parent.setSecondaryText(Messages.getString("CommsThread.20") + " in " + _diffMillis + " seconds.");
                Log.println(true, "Received disk image " + name + " with errors."); //$NON-NLS-1$ //$NON-NLS-2$
              }
            }
            else
            {
              _parent.setSecondaryText(Messages.getString("CommsThread.21"));
              _transport.flushReceiveBuffer();
              _transport.flushSendBuffer();
            }
          }
          catch (IOException ex2)
          {
            _transport.writeByte(0x1a); // ADT protocol - unable to write file
            _transport.pushBuffer();
          }
          finally
          {
            if (fos != null) try
            {
              fos.close();
            }
            catch (IOException io)
            {}
          }
        }
      }
    }
    catch (TransportTimeoutException e)
    {
      Log.println(true, "receive140kDisk() aborting due to timeout.");
      _parent.setSecondaryText(Messages.getString("CommsThread.21"));
    }
    Log.println(false, "receive140kDisk() exit.");
  }

  public int receivePacket(byte[] buffer, int offset, int buffNum, boolean preamble)
  // Receive a packet with RLE compression
  // Returns:
  // 0 on successful read - block/halfblock numbers, CRC matched
  // -1 on inability to read a packet successfully (timeouts, retries exhausted)
  {
    int byteCount, retries = 0;
    int received_crc = -1, computed_crc = 0;
    int incomingBlockNum = 0, incomingHalf = 0, blockNum, halfNum;
    byte data = 0x00, prev, crc1 = 0, crc2 = 0;
    int rc = 0;
    boolean restarting = false;

    Log.println(false, "CommsThread.receivePacket() entry; offset " + offset + ", buffNum = " + buffNum + ".");
    do
    {
      // Log.println(false, " top of receivePacket loop.");
      rc = 0;
      prev = 0;
      restarting = false;
      if (((preamble) && (_client01xCompatibleProtocol == false)) || (_transport.getClass() == UDPTransport.class)
          || (_transport.getClass() == AudioTransport.class))
      /*
       * Remember, UDP and Audio originally had a preamble from the beginning.
       */
      {
        try
        {
          // Wait for the block number...
          incomingBlockNum = UnsignedByte.intValue(waitForData(15));
          incomingBlockNum = incomingBlockNum + ((UnsignedByte.intValue(waitForData(15)) * 256));
          data = waitForData(15);
          incomingHalf = Math.abs(2 - data); // Get the half block

          blockNum = buffNum / 2;
          halfNum = buffNum % 2;
          Log.println(false, "CommsThread.receivePacket() BlockNum: " + blockNum + " local lsb: "
              + UnsignedByte.toString(UnsignedByte.loByte(blockNum)) + " Incoming lsb: "
              + UnsignedByte.toString(UnsignedByte.loByte(incomingBlockNum)) + " halfNum: " + halfNum
              + " Incoming halfNum: " + incomingHalf);
          if ((incomingBlockNum != blockNum) || (incomingHalf != halfNum))
          {
            if ((incomingBlockNum == (blockNum - 1) && (incomingHalf == (1 - halfNum))))
            {
              rc = -2;
              Log.println(false, "Block numbers were close (full); acknowledging.");
              _transport.pauseIncorrectCRC();
            }
            else
              if ((incomingBlockNum == blockNum) && (incomingHalf == (1 - halfNum)))
              {
                rc = -2;
                Log.println(false, "Block numbers were close (half); acknowledging.");
                _transport.pauseIncorrectCRC();
              }
              else
              {
                rc = -1;
                Log.println(false, "Block numbers didn't match.");
                _transport.pauseIncorrectCRC();
              }
          }
          else
            rc = 0;
        }
        catch (TransportTimeoutException tte)
        {
          rc = -1;
          Log.println(true, "CommsThread.receivePacket() TransportTimeoutException! (location 1)");
        }
      } // end if (preamble)
      if (rc == 0)
      {
        for (byteCount = 0; byteCount < 256;)
        {
          // Log.println(false, "CommsThread.receivePacket() byteCount: " +
          // byteCount);
          try
          {
            // Wait for a byte...
            data = waitForData(15);
            // Log.println(false, "Received: " + UnsignedByte.toString(data));
            if (UnsignedByte.intValue(data) > 0)
            {
              prev += UnsignedByte.intValue(data);
              // Log.println(false,"Byte[" +
              // UnsignedByte.toString(UnsignedByte.loByte(byteCount)) +
              // "]="+UnsignedByte.toString(prev) + " (native)");
              // if (byteCount % 32 == 0) Log.println(false,"");
              buffer[offset + byteCount++] = prev;
            }
            else
            {
              data = waitForData(15); // We have a run - get the length!
              // Log.println(false,"CommsThread.receivePacket() Received run
              // length: "+UnsignedByte.toString(data));
              do
              {
                // Log.println(false,"Byte[" +
                // UnsignedByte.toString(UnsignedByte.loByte(byteCount)) +
                // "]="+UnsignedByte.toString(prev) + " (rle)");
                // if (byteCount % 32 == 0) Log.println(false,"");
                buffer[offset + byteCount++] = prev;
                // Log.print(false,UnsignedByte.toString(buffer[offset +
                // byteCount - 1]) + " ");
              }
              while (_shouldRun && byteCount < 256 && byteCount != UnsignedByte.intValue(data));
            }
            if (!_shouldRun)
            {
              rc = -1;
              break;
            }
          }
          catch (TransportTimeoutException tte)
          {
            rc = -1;
            Log.println(true, "CommsThread.receivePacket() TransportTimeoutException! (location 2)");
            break;
          }
        }
        if (_shouldRun && !restarting && rc == 0)
        {
          Log.println(false, "Receiving CRC bytes...");
          try
          {
            crc1 = waitForData(15);
            crc2 = waitForData(15);
            received_crc = UnsignedByte.intValue(crc1, crc2);
            computed_crc = doCrc(buffer, offset, 256);
            if (received_crc != computed_crc)
            {
              rc = -1;
              Log.println(true, "Incorrect CRC. Computed: " + computed_crc + " Received: " + received_crc); //$NON-NLS-1$ //$NON-NLS-2$
              _transport.pauseIncorrectCRC();
            }
            else
            {
              Log.println(false, "Correct CRC. Computed: " + computed_crc + " Received: " + received_crc); //$NON-NLS-1$ //$NON-NLS-2$
              rc = 0;
            }
          }
          catch (TransportTimeoutException tte2)
          {
            Log.println(true, "CommsThread.receivePacket() TransportTimeoutException! (location 3)");
            rc = -1;
          }
        }
      }
      if (rc == 0)
      {
        _transport.writeByte(ACK);
        _transport.pushBuffer();
        _transport.flushReceiveBuffer();
        _transport.flushSendBuffer();
      }
      else
        if (rc == -2)
        {
          /*
           * We received an out-of-sync packet (likely a duplicate). Acknowledge
           * it, and swing around again for another try.
           */
          _transport.writeByte(ACK);
          _transport.pushBuffer();
          _transport.flushReceiveBuffer();
          _transport.flushSendBuffer();
          retries++;
          Log.println(false, "CommsThread.receivePacket() didn't work - out-of-sync packet received.");
        }
        else
        {
          _transport.flushReceiveBuffer();
          _transport.flushSendBuffer();
          retries++;
          Log.println(false, "CommsThread.receivePacket() didn't work; will retry #" + retries+".");
          // For audio transport, pause for an increasing amount of time each time we retry.
          // What's that called - progressive backoff?
          if (_transport.transportType() == ATransport.TRANSPORT_TYPE_AUDIO)
          {
            try
            {
              Log.println(false, "CommsThread.receivePacket() audio backoff sleeping for " + (retries * 200) + " seconds.");
              sleep(retries * 200); // Sleep 2 seconds for each time we have to retry
            }
            catch (InterruptedException e)
            {
              Log.println(false, "CommsThread.receivePacket() audio backoff sleep was interrupted.");
            }
          }
          _transport.writeByte(NAK);
          _transport.pushBuffer();
        }
    }
    while ((rc != 0) && (_shouldRun == true) && (retries < _maxRetries));
    Log.println(false, "CommsThread.receivePacket() exit.");

    return rc;
  }

  public byte waitForData(int timeout) throws TransportTimeoutException
  {
    /*
     * Fix me This needs to figure out a better way to set timeouts - not once
     * per byte read, but only when different timing transitions are needed.
     */
    // Log.println(false, "CommsThread.waitForData() entry, timeout: " +
    // timeout);
    byte oneByte = 0;
    boolean readYet = false;
    while ((readYet == false) && (_shouldRun == true))
    {
      try
      {
        if (_transport != null)
        {
          oneByte = _transport.readByte(timeout);
          readYet = true;
        }
        else
        {
          _shouldRun = false;
        }
      }
      catch (TransportTimeoutException tte)
      {
        Log.println(false, "CommsThread.waitForData.TransportTimeoutException! (location 0)");
        throw tte;
        // _shouldRun = false;
      }
      catch (Exception e)
      {
        Log.printStackTrace(e);
      }
    }
    return oneByte;
  }

  public String receiveName() throws TransportTimeoutException
  {
    byte oneByte;
    StringBuffer buf = new StringBuffer();

    for (int i = 0; i < 256; i++)
    {
      if (!_shouldRun) break;
      try
      {
        oneByte = waitForData(15);
      }
      catch (TransportTimeoutException e)
      {
        throw e;
      }
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

  public int requestSend(String resource)
  {
    return requestSend(resource, false, 0, 0);
  }

  public int requestSend(String resource, boolean reallySend, int pacing, int speed)
  {
    int fileSize = 0;
    int slowFirstLines = 0;
    int slowLastLines = 0;
    Log.println(false, "CommsThread.requestSend() request: " + resource + ", reallySend = " + reallySend);
    String resourceName;
    InputStream is = null;
    if (_transport.transportType() == ATransport.TRANSPORT_TYPE_AUDIO)
    {
      if (resource.equals(Messages.getString("Gui.BS.ProDOS"))) resourceName = "org/adtpro/resources/PD1.raw";
      else
        if (resource.equals(Messages.getString("Gui.BS.ProDOS2"))) resourceName = "org/adtpro/resources/PD2.raw";
        else
          if (resource.equals(Messages.getString("Gui.BS.ProDOSFormat"))) resourceName = "org/adtpro/resources/format.raw";
          else
            if (resource.equals(Messages.getString("Gui.BS.DOS"))) resourceName = "org/adtpro/resources/EsDOS1.raw";
            else
              if (resource.equals(Messages.getString("Gui.BS.DOS2"))) resourceName = "org/adtpro/resources/EsDOS2.raw";
              else
                if (resource.equals(Messages.getString("Gui.BS.ADT"))) resourceName = "org/adtpro/resources/adt.raw";
                else
                  if (resource.equals(Messages.getString("Gui.BS.ADTPro"))) resourceName = "org/adtpro/resources/adtpro.raw";
                  else
                    if (resource.equals(Messages.getString("Gui.BS.ADTProAudio"))) resourceName = "org/adtpro/resources/adtproaud.raw";
                    else
                      if (resource.equals(Messages.getString("Gui.BS.ADTProEthernet"))) resourceName = "org/adtpro/resources/adtproeth.raw";
                      else
                        resourceName = "'CommsThread.requestSend() - not set! (AudioTransport)'";
    }
    else
    {
      if (resource.equals(Messages.getString("Gui.BS.ProDOS")))
      {
        resourceName = "org/adtpro/resources/PD1.dmp";
        slowFirstLines = 5;
      }
      else
        if (resource.equals(Messages.getString("Gui.BS.ProDOS2")))
        {
          resourceName = "org/adtpro/resources/PD2.dmp";
          slowFirstLines = 4;
        }
        else
          if (resource.equals(Messages.getString("Gui.BS.ProDOSFormat")))
          {
            resourceName = "org/adtpro/resources/format.dmp";
            slowFirstLines = 5;
          }
          else
            if (resource.equals(Messages.getString("Gui.BS.DOS")))
            {
              resourceName = "org/adtpro/resources/EsDOS.dmp";
              slowFirstLines = 3;
              slowLastLines = 0;
            }
            else
              if (resource.equals(Messages.getString("Gui.BS.ADT")))
              {
                resourceName = "org/adtpro/resources/adt.dmp";
                slowFirstLines = 5;
                slowLastLines = 4;
              }
              else
                if (resource.equals(Messages.getString("Gui.BS.ADTPro")))
                {
                  resourceName = "org/adtpro/resources/adtpro.dmp";
                  slowFirstLines = 5;
                  slowLastLines = 4;
                }
                else
                  if (resource.equals(Messages.getString("Gui.BS.ADTProAudio")))
                  {
                    resourceName = "org/adtpro/resources/adtproaud.dmp";
                    slowFirstLines = 5;
                    slowLastLines = 4;
                  }
                  else
                    if (resource.equals(Messages.getString("Gui.BS.ADTProEthernet")))
                    {
                      resourceName = "org/adtpro/resources/adtproeth.dmp";
                      slowFirstLines = 5;
                      slowLastLines = 4;
                    }
                    else
                      resourceName = "'CommsThread.requestSend() - not set! (non-AudioTransport)'";
    }
    Log.println(false, "CommsThread.requestSend() seeking resource named " + resourceName);
    is = ADTPro.class.getClassLoader().getResourceAsStream(resourceName);
    if (is != null)
    {
      try
      {
        fileSize = is.available();
      }
      catch (IOException e)
      {
        Log.printStackTrace(e);
      }
      if (reallySend)
      {
        // Run this on a thread...
        Log.println(false, "CommsThread.requestSend() Reading " + resourceName);
        _parent.setMainText(Messages.getString("CommsThread.4")); //$NON-NLS-1$
        _parent.setSecondaryText(resourceName); //$NON-NLS-1$
        _worker = new Worker(resource, is, pacing, speed, slowFirstLines, slowLastLines);
        _worker.start();
      }
      else
        Log.println(false, "CommsThread.requestSend() found file sized " + fileSize + " bytes.");
    }
    else
    {
      Log.println(true, "Unable to find resource named " + resourceName + " to send."); //$NON-NLS-1$  //$NON-NLS-2$
    }
    return fileSize;
  }

  public void requestStop()
  {
    Log.println(false, "CommsThread.requestStop() entry.");
    _shouldRun = false;
    if (_worker != null)
    {
      _worker.interrupt();
    }
    try
    {
      Log.println(false, "CommsThread.requestStop() about to close transport.");
      _transport.close();
    }
    catch (Exception ex)
    {
      Log.printStackTrace(ex);
    }
    Log.println(false, "CommsThread.requestStop() exit.");
  }

  public boolean isBusy()
  {
    return _busy;
  }

  /*
   * Worker class is a thread that sends bootstrapping data.
   */
  public class Worker extends Thread
  {

    public Worker(String resource, InputStream is, int pacing, int speed, int slowFirstLines, int slowLastLines)
    {
      Log.println(false, "CommsThread Worker inner class instantiation.");
      Log.println(false, "CommsThread Worker Pacing = " + pacing + ", speed = " + speed);
      _is = is;
      _pacing = pacing;
      _speed = speed;
      _slowFirst = slowFirstLines;
      _slowLast = slowLastLines;
      _resource = resource;
    }

    public void run()
    {
      Log.println(false, "CommsThread.Worker.run() entry.");
      int bytesRead, bytesAvailable;
      _startTime = new GregorianCalendar();
      _busy = true;
      if (_transport.transportType() == ATransport.TRANSPORT_TYPE_AUDIO)
      {
        try
        {
          bytesAvailable = _is.available();
          _parent.setProgressMaximum(bytesAvailable);
          byte[] buffer = new byte[bytesAvailable];
          bytesRead = _is.read(buffer);
          Log.println(false, "CommsThread.Worker.run() read " + bytesRead + " bytes from the stream.");
          while (bytesRead < bytesAvailable)
          {
            bytesRead += _is.read(buffer, bytesRead, bytesAvailable - bytesRead);
            Log.println(false, "CommsThread.Worker.run() read " + bytesRead + " more bytes from the stream.");
          }
          ((AudioTransport) _transport).writeBigBytes(buffer);
          ((AudioTransport) _transport).pushBigBuffer(_parent);
          String message = _transport.getInstructionsDone(_resource);
          if (!message.equals(""))
          {
            _parent.requestSendFinished(message);
          }
        }
        catch (Exception e)
        {
          Log.printStackTrace(e);
        }
      }
      else
      {
        try
        {
          bytesAvailable = _is.available();
          char[] buffer = new char[bytesAvailable];
          InputStreamReader isr = new InputStreamReader(_is);
          bytesRead = isr.read(buffer);
          Log.println(false, "CommsThread.Worker.run() read " + bytesRead + " bytes from the stream.");
          while (bytesRead < bytesAvailable)
          {
            bytesRead += isr.read(buffer, bytesRead, bytesAvailable - bytesRead);
            Log.println(false, "CommsThread.Worker.run() read " + bytesRead + " more bytes from the stream.");
          }
          Log.println(false, "commsThread.Worker.run() speed = " + _speed + " pacing = " + _pacing);
          _parent.setProgressMaximum(buffer.length);
          _transport.setSlowSpeed(_speed);
          int numLines = 0;
          /*
           * Go through once and just count the number of lines in the file. We
           * use that to determine when to start slowing down the pacing.
           */
          for (int i = 0; i < buffer.length; i++)
          {
            if (buffer[i] == 0x0d) numLines++;
          }
          int currentLine = 0;
          /*
           * "Slow" pacing is 500ms. If they asked for pacing even slower than
           * that, we need to respect that too. So take the max of their pacing
           * and 500ms.
           */
          int slowPacing = 500;
          if (slowPacing < _pacing) slowPacing = _pacing;
          /*
           * Start sending the file.
           */
          for (int i = 0; i < buffer.length; i++)
          {
            if (_shouldRun == false)
            {
              Log.println(false, "CommsThread.Worker.run() told to stop.");
              break;
            }
            /*
             * We hit the end of a line.
             */
            if (buffer[i] == 0x0d)
            {
              _transport.writeByte(0x8d);
              _transport.flushSendBuffer();
              try
              {
                /*
                 * Are we within the boundaries of what was supposed to be send
                 * with slower pacing - at the beginning or end of the file?
                 */
                if ((_slowFirst > currentLine) || (currentLine > (numLines - _slowLast)))
                {
                  sleep(slowPacing);
                }
                else
                {
                  sleep(_pacing);
                }
              }
              catch (InterruptedException e)
              {
                Log.println(false, "CommsThread.Worker.run() interrupted.");
                if (_shouldRun == false)
                {
                  Log.println(false, "CommsThread.Worker.run() told to stop, again...");
                  break;
                }
              }
              currentLine++;
            }
            else
              if (buffer[i] != 0x0a) _transport.writeByte(buffer[i]);
            if (_shouldRun)
            {
              _parent.setProgressValue(i + 1);
            }
          }
          if (_shouldRun)
          {
            _transport.pushBuffer();
            _endTime = new GregorianCalendar();
            _diffMillis = (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000;
            //sleep(1000);
            _parent.setSecondaryText(Messages.getString("CommsThread.22") + " in " + _diffMillis + " seconds.");
            Log.println(true, "Text file sent in "
                + (float) (_endTime.getTimeInMillis() - _startTime.getTimeInMillis()) / (float) 1000 + " seconds.");
            String message = _transport.getInstructionsDone(_resource);
            if (!message.equals(""))
            {
              _parent.requestSendFinished(message);
            }
          }
        }
        catch (Exception e)
        {
          Log.printStackTrace(e);
        }
      }
      if (_shouldRun) _transport.flushReceiveBuffer();
      _transport.setFullSpeed();
      _busy = false;
      Log.println(false, "CommsThread.Worker.run() exit.");
    }

    public void requestStop()
    {
      _shouldRun = false;
      _busy = false;
    }

    InputStream _is;

    int _speed;

    int _pacing;

    int _slowFirst = 0;

    int _slowLast = 0;
    
    String _resource = null;
  }

  public int transportType()
  {
    return _transport.transportType();
  }

  public boolean supportsBootstrap()
  {
    return _transport.supportsBootstrap();
  }

  public void setHardwareHandshaking(boolean state)
  {
    if (_transport.transportType() == ATransport.TRANSPORT_TYPE_SERIAL)
    {
      ((SerialTransport) _transport).setHardwareHandshaking(state);
    }
  }

  public void setSpeed(int speed)
  {
    if (_transport.transportType() == ATransport.TRANSPORT_TYPE_SERIAL)
    {
      try
      {
        Log.println(false, "CommsThread.setSpeed() Attempting to set the serial port's speed to " + speed);
        ((SerialTransport) _transport).setSpeed(speed);
        Log.println(false, "CommsThread.setSpeed() successful.");
      }
      catch (Exception e)
      {
        Log.printStackTrace(e);
        Log.println(true, "CommsThread.setSpeed() failed to set the port speed to " + speed + ".");
      }
    }
  }

  public void setParms(String portName, int speed, boolean hardware)
  {
    if (_transport.transportType() == ATransport.TRANSPORT_TYPE_SERIAL)
    {
      try
      {
        ((SerialTransport) _transport).setParms(portName, speed, hardware);
      }
      catch (Exception e)
      {
        Log.printStackTrace(e);
        Log.println(true, "CommsThread.setParms() failed to set the port parameters.");
      }
    }
  }

  public void setProtocolCompatibility(boolean state)
  {
    _client01xCompatibleProtocol = state;
  }

  public String getInstructions(String guiString, int size, int speed)
  {
    return (_transport.getInstructions(guiString, size, speed));
  }

  public static int lastFileNumber = 0;
}
