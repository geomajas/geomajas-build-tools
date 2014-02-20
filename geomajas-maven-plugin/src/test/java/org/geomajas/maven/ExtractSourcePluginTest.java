/*
 * This is part of Geomajas, a GIS framework, http://www.geomajas.org/.
 *
 * Copyright 2008-2014 Geosparc nv, http://www.geosparc.com/, Belgium.
 *
 * The program is available in open source according to the GNU Affero
 * General Public License. All contributions in this program are covered
 * by the Geomajas Contributors License Agreement. For full licensing
 * details, see LICENSE.txt in the project root.
 */

package org.geomajas.maven;

import org.junit.Assert;
import org.junit.Test;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import java.io.File;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * Tests for ExtractSourcePlugin
 *
 * @author Joachim Van der Auwera
 */
public class ExtractSourcePluginTest {

	@Test
	public void testPrepareLinesTabs() throws Exception {
		List<String> list  = new ArrayList<String>();
		list.add("some\ttest");
		ExtractSourcePlugin esp = new ExtractSourcePlugin();
		esp.prepareLines(list);
		Assert.assertEquals("some    test", list.get(0));
	}

	@Test
	public void testPrepareLinesFixIndent() throws Exception {
		List<String> list  = new ArrayList<String>();
		list.add("   line {");
		list.add("      blabla");
		list.add("   }");
		ExtractSourcePlugin esp = new ExtractSourcePlugin();
		esp.prepareLines(list);
		Assert.assertEquals("line {", list.get(0));
		Assert.assertEquals("   blabla", list.get(1));
		Assert.assertEquals("}", list.get(2));
	}

	@Test
	public void testPrepareLinesXmlEscape() throws Exception {
		List<String> list  = new ArrayList<String>();
		list.add("<test>black & white</test>");
		ExtractSourcePlugin esp = new ExtractSourcePlugin();
		esp.prepareLines(list);
		// should not replace, block will be stored in CDATA
		//Assert.assertEquals("&lt;test&gt;black &amp; white&lt;/test&gt;", list.get(0));
		Assert.assertEquals("<test>black & white</test>", list.get(0));
	}

	@Test
	public void testExtractAnnotatedCodeFromJavaFile() throws Exception {
		File source = new File(getClass().getResource("/org/geomajas/maven/test.java").toURI());
		String tempDir = System.getProperty("java.io.tmpdir") + "/geomajasMavenPluginTest/" + new Date().getTime();
		File destination = new File(tempDir);
		ExtractSourcePlugin esp = new ExtractSourcePlugin();
		esp.extractAnnotatedCode(source, destination);
		Assert.assertEquals(1, destination.listFiles().length);
		File resultFile = destination.listFiles()[0];
		Assert.assertEquals("testFile.xml", resultFile.getName());
		// parse xml
		DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
		DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
		Document doc = dBuilder.parse(resultFile);
		doc.getDocumentElement().normalize();

		// contains one tag programlisting, with attribute language and content CDATA
		NodeList list = doc.getDocumentElement().getElementsByTagName("programlisting");
		Assert.assertEquals(1, list.getLength());
		Node programlistingNode = list.item(0);
		Assert.assertEquals(1, programlistingNode.getAttributes().getLength());
		Node languageItem = programlistingNode.getAttributes().item(0);
		Assert.assertEquals("language", languageItem.getNodeName());
		Assert.assertEquals("java", languageItem.getNodeValue());
		Node textContent = programlistingNode.getFirstChild();
		Assert.assertEquals("Text to be extracted.", textContent.getNodeValue());
		//analyze xml
		//delete temporary result file
		for (File subfile : destination.listFiles()) {
			subfile.delete();
		}
		destination.delete();
	}

	@Test
	public void testExtractAnnotatedCodeFromXmlFile() throws Exception {
		File source = new File(getClass().getResource("/org/geomajas/maven/test.xml").toURI());
		String tempDir = System.getProperty("java.io.tmpdir") + "/geomajasMavenPluginTest/" + new Date().getTime();
		File destination = new File(tempDir);
		ExtractSourcePlugin esp = new ExtractSourcePlugin();
		esp.extractAnnotatedCode(source, destination);
		Assert.assertEquals(1, destination.listFiles().length);
		File resultFile = destination.listFiles()[0];
		Assert.assertEquals("testFile.xml", resultFile.getName());
		// parse xml
		DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
		DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
		Document doc = dBuilder.parse(resultFile);
		doc.getDocumentElement().normalize();

		// contains one tag programlisting, with attribute language and content CDATA
		NodeList list = doc.getDocumentElement().getElementsByTagName("programlisting");
		Assert.assertEquals(1, list.getLength());
		Node programlistingNode = list.item(0);
		Assert.assertEquals(1, programlistingNode.getAttributes().getLength());
		Node languageItem = programlistingNode.getAttributes().item(0);
		Assert.assertEquals("language", languageItem.getNodeName());
		Assert.assertEquals("xml", languageItem.getNodeValue());
		Node textContent = programlistingNode.getFirstChild();
		Assert.assertEquals("<tag>Text to be extracted.</tag>", textContent.getNodeValue());
		//analyze xml
		//delete temporary result file
		for (File subfile : destination.listFiles()) {
			subfile.delete();
		}
		destination.delete();
	}
}
