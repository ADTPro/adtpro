/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006 by David Schmidt
 * 1110325+david-schmidt@users.noreply.github.com
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

package org.adtpro.gui;

import java.awt.*;

public class FrameUtils
{
  /**
   * center: center a Rectangle on screen coordinates
   * 
   * @param dim - Dimension of desired component
   * @return Rectangle, centered on screen coordinates
   */
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

  /**
   * center: center a Rectangle within a viewport
   * 
   * @param dim - Dimension of desired component
   * @param r - Rectangle of viewport
   * @return Rectangle, centered on rectangle coordinates
   */
  public static Rectangle center(Dimension dim, Rectangle r)
  {
    final Rectangle centeredRect =
    new Rectangle( (r.width  - dim.width)  /2 + r.x,
                   (r.height - dim.height) /2 + r.y,
                   dim.width,
                   dim.height);
    return centeredRect;
  }

  /**
   * @param r - desired rectangle
   * @return true if the rectangle will fit on the screen
   */
  public static boolean fits(Rectangle r)
  {
    boolean ret = false;
    final Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();

    if (((r.x + r.width) <= screenSize.width) && 
        ((r.y + r.height) <= screenSize.height))
    {
      ret = true;
    }
    return ret;
  }

  private FrameUtils()
  {
    // Prohibit instantiation
  }
}