/*
 * This is part of Geomajas, a GIS framework, http://www.geomajas.org/.
 *
 * Copyright 2008-2016 Geosparc nv, http://www.geosparc.com/, Belgium.
 *
 * The program is available in open source according to the GNU Affero
 * General Public License. All contributions in this program are covered
 * by the Geomajas Contributors License Agreement. For full licensing
 * details, see LICENSE.txt in the project root.
 */

package org.geomajas.checkstyle;

import java.io.IOException;
import java.io.Reader;

/**
 * A Reader that reads from an underlying String array, assuming each
 * array element corresponds to one line of text.
 * <p>
 * <strong>Note: This class is not thread safe, concurrent reads might produce
 * unexpected results! </strong> Checkstyle only works with one thread so
 * currently there is no need to introduce synchronization here.
 * </p>
 *
 * @author <a href="mailto:lkuehne@users.sourceforge.net">Lars Kühne</a>
 *         <p/>
 *         This file was copied from checkstyle and is originally licensed as LGPL.
 */
final class StringArrayReader extends Reader {

	/** the underlying String array */
	private final String[] mUnderlyingArray;

	/** array containing the length of the strings. */
	private final int[] mLenghtArray;

	/** the index of the currently read String */
	private int mArrayIdx;

	/** the index of the next character to be read */
	private int mStringIdx;

	/** flag to tell whether an implicit newline has to be reported */
	private boolean mUnreportedNewline;

	/** flag to tell if the reader has been closed */
	private boolean mClosed;

	/**
	 * Creates a new StringArrayReader.
	 *
	 * @param aUnderlyingArray the underlying String array.
	 */
	StringArrayReader(String[] aUnderlyingArray) {
		final int length = aUnderlyingArray.length;
		mUnderlyingArray = new String[length];
		System.arraycopy(aUnderlyingArray, 0, mUnderlyingArray, 0, length);

		//additionally store the length of the strings
		//for performance optimization
		mLenghtArray = new int[length];
		for (int i = 0; i < length; i++) {
			mLenghtArray[i] = mUnderlyingArray[i].length();
		}
	}

	@Override
	public void close() {
		mClosed = true;
	}

	/** @return whether data is available that has not yet been read. */
	private boolean dataAvailable() {
		return (mUnderlyingArray.length > mArrayIdx);
	}

	@Override
	public int read(char[] aCbuf, int aOff, int aLen) throws IOException {
		ensureOpen();

		int retVal = 0;

		if (!mUnreportedNewline && (mUnderlyingArray.length <= mArrayIdx)) {
			return -1;
		}

		while ((retVal < aLen) && (mUnreportedNewline || dataAvailable())) {
			if (mUnreportedNewline) {
				aCbuf[aOff + retVal] = '\n';
				retVal++;
				mUnreportedNewline = false;
			}

			if ((retVal < aLen) && dataAvailable()) {
				final String currentStr = mUnderlyingArray[mArrayIdx];
				final int currentLenth = mLenghtArray[mArrayIdx];
				final int srcEnd = Math.min(currentLenth,
						mStringIdx + aLen - retVal);
				currentStr.getChars(mStringIdx, srcEnd, aCbuf, aOff + retVal);
				retVal += srcEnd - mStringIdx;
				mStringIdx = srcEnd;

				if (mStringIdx >= currentLenth) {
					mArrayIdx++;
					mStringIdx = 0;
					mUnreportedNewline = true;
				}
			}
		}
		return retVal;
	}

	@Override
	public int read() throws IOException {
		if (mUnreportedNewline) {
			mUnreportedNewline = false;
			return '\n';
		}

		if ((mArrayIdx < mUnderlyingArray.length)
				&& (mStringIdx < mLenghtArray[mArrayIdx])) {
			// this is the common case,
			// avoid char[] creation in super.read for performance
			ensureOpen();
			return mUnderlyingArray[mArrayIdx].charAt(mStringIdx++);
		}
		// don't bother duplicating the new line handling above
		// for the uncommon case
		return super.read();
	}

	/**
	 * Throws an IOException if the reader has already been closed.
	 *
	 * @throws IOException if the stream has been closed
	 */
	private void ensureOpen() throws IOException {
		if (mClosed) {
			throw new IOException("already closed");
		}
	}
}
