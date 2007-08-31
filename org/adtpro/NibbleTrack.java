package org.adtpro;

public class NibbleTrack
{
  public NibbleTrack()
  {
    trackBuffer = new byte[6656];
  }
  public double accuracy = 0.0;
  public int foundLength = 0;
  public byte[] trackBuffer;
}