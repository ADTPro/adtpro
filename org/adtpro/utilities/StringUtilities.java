/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2009 by David Schmidt
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

package org.adtpro.utilities;

public class StringUtilities

{
  /*****************************************************************************
   * This method replaces the preValue with the postValue in the originalString.
   * 
   * @param originalString
   *          the string to have replacements
   * @param preValue
   *          The substring value that the string currently contains
   * @param postValue
   *          The substring value to replace the preValue
   * 
   * @return String representing the substituted value(s)
   ****************************************************************************/

  public static String replaceSubstring(final String originalString, final String preValue,
      final String postValue)
  {
    if (preValue.equals(""))
    {
      throw new IllegalArgumentException("Old pattern must have content.");
    }

    final StringBuffer result = new StringBuffer();
    //startIdx and idxOld delimit various chunks of aInput; these
    //chunks always end where aOldPattern begins
    int startIdx = 0;
    int idxOld = 0;
    while ((idxOld = originalString.indexOf(preValue, startIdx)) >= 0)
    {
      //grab a part of aInput which does not include aOldPattern
      result.append(originalString.substring(startIdx, idxOld));
      //add aNewPattern to take place of aOldPattern
      result.append(postValue);

      //reset the startIdx to just after the current match, to see
      //if there are any further matches
      startIdx = idxOld + preValue.length();
    }
    //the final chunk will go to the end of aInput
    result.append(originalString.substring(startIdx));
    return result.toString();
  }
}