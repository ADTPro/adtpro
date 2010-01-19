package org.adtpro.shrinkit;

/**
 * Define and decode the thread_class field.
 * @author robgreene@users.sourceforge.net
 */
public enum ThreadClass {
	MESSAGE, CONTROL, DATA, FILENAME;

	/**
	 * Find the given ThreadClass.
	 * @throws IllegalArgumentException if the thread_class is unknown
	 */
	public static ThreadClass find(int threadClass) {
		switch (threadClass) {
		case 0x0000: return MESSAGE;
		case 0x0001: return CONTROL;
		case 0x0002: return DATA;
		case 0x0003: return FILENAME;
		default:
			throw new IllegalArgumentException("Unknown thread_class of " + threadClass);
		}
	}
}
