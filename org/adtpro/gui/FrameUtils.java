package org.adtpro.gui;

import java.awt.*;

public class FrameUtils
{
  public static Rectangle center(Dimension dim)
  {
    final Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();

    final Rectangle centeredRect =
    new Rectangle( (screenSize.width  - dim.width)  /2,
                   (screenSize.height - dim.height) /2,
                   dim.width,
                   dim.height);
    return centeredRect;
  }
  private FrameUtils()
  {
    // Prohibit instantiation
  }
}