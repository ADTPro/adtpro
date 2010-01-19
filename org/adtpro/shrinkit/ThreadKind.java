package org.adtpro.shrinkit;

/**
 * Define and decode the thread_kind field.
 * @author robgreene@users.sourceforge.net
 */
public enum ThreadKind {
	ASCII_TEXT, ALLOCATED_SPACE, APPLE_IIGS_ICON, CREATE_DIRECTORY, DATA_FORK, DISK_IMAGE, RESOURCE_FORK,
	FILENAME;

	/**
	 * Find the specific ThreadKind.
	 * @throws IllegalArgumentException when the thread_kind cannot be determined
	 */
	public static ThreadKind find(int threadKind, ThreadClass threadClass) {
		switch (threadClass) {
		case MESSAGE:
			switch (threadKind) {
			case 0x0000: return ASCII_TEXT;
			case 0x0001: return ALLOCATED_SPACE;
			case 0x0002: return APPLE_IIGS_ICON;
			}
			throw new IllegalArgumentException("Unknown thread_kind for message thread_class of " + threadKind);
		case CONTROL:
			if (threadKind == 0x0000) return CREATE_DIRECTORY;
			throw new IllegalArgumentException("Unknown thread_kind for control thread_class of " + threadKind);
		case DATA:
			switch (threadKind) {
			case 0x0000: return DATA_FORK;
			case 0x0001: return DISK_IMAGE;
			case 0x0002: return RESOURCE_FORK;
			}
			throw new IllegalArgumentException("Unknown thread_kind for data thread_class of " + threadKind);
		case FILENAME:
			if (threadKind == 0x0000) return FILENAME;
			throw new IllegalArgumentException("Unknown thread_kind for filename thread_class of " + threadKind);
		default:
			throw new IllegalArgumentException("Unknown thread_class of " + threadClass);
		}
	}
}
