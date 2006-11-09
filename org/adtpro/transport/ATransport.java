package org.adtpro.transport;

import java.io.IOException;

public abstract class ATransport
{
  public abstract void open() throws Exception;
  public abstract void writeByte(byte datum);
  public abstract void writeByte(char datum);
  public abstract void writeByte(int datum);
  public abstract void writeBytes(byte data[]);
  public abstract void writeBytes(String str);
  public abstract byte readByte(int timeout) throws Exception;
  public abstract void pushBuffer();
  public abstract void flushSendBuffer();
  public abstract void flushReceiveBuffer();
//  public abstract void pullBuffer() throws Exception;
  public abstract void close() throws Exception;
}
