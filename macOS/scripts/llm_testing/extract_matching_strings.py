#!/usr/bin/env python3
"""
Extract Matching Strings Script

This script extracts specific strings from a full XLIFF translation file
based on the string IDs present in a source XLIFF file.

Usage: Extract only the strings that were translated by LLMs from the full
human translation file for comparison purposes.
"""

import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
import argparse

# XLIFF namespace
XLIFF_NS = "urn:oasis:names:tc:xliff:document:1.2"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"

# Register namespaces
ET.register_namespace('', XLIFF_NS)
ET.register_namespace('xsi', XSI_NS)

class XLIFFExtractor:
    def __init__(self):
        """Initialize the XLIFF extractor."""
        pass
    
    def parse_xliff(self, xliff_path: str) -> ET.ElementTree:
        """Parse an XLIFF file and return the ElementTree."""
        try:
            tree = ET.parse(xliff_path)
            return tree
        except ET.ParseError as e:
            print(f"Error parsing XLIFF file {xliff_path}: {e}")
            sys.exit(1)
        except FileNotFoundError:
            print(f"Error: File not found: {xliff_path}")
            sys.exit(1)
    
    def get_string_ids(self, tree: ET.ElementTree) -> set:
        """
        Extract all string IDs from an XLIFF file.
        
        Returns:
            Set of string IDs
        """
        root = tree.getroot()
        string_ids = set()
        
        # Find all trans-unit elements
        for trans_unit in root.findall(f".//{{{XLIFF_NS}}}trans-unit"):
            string_id = trans_unit.get('id', '')
            if string_id:
                string_ids.add(string_id)
        
        return string_ids
    
    def extract_matching_strings(self, source_tree: ET.ElementTree, target_ids: set) -> ET.ElementTree:
        """
        Create a new XLIFF tree containing only strings with IDs in target_ids.
        
        Args:
            source_tree: The XLIFF tree to extract strings from
            target_ids: Set of string IDs to include
            
        Returns:
            New ElementTree with only matching strings
        """
        root = source_tree.getroot()
        new_root = ET.Element(root.tag, root.attrib)
        
        # Copy all root attributes and namespace declarations
        for key, value in root.attrib.items():
            new_root.set(key, value)
        
        # Process each file element
        for file_elem in root.findall(f"{{{XLIFF_NS}}}file"):
            new_file = ET.SubElement(new_root, f"{{{XLIFF_NS}}}file")
            
            # Copy file attributes
            for key, value in file_elem.attrib.items():
                new_file.set(key, value)
            
            # Copy header
            header = file_elem.find(f"{{{XLIFF_NS}}}header")
            if header is not None:
                new_header = ET.SubElement(new_file, f"{{{XLIFF_NS}}}header")
                for child in header:
                    new_header.append(child)
            
            # Process body
            body = file_elem.find(f"{{{XLIFF_NS}}}body")
            if body is not None:
                new_body = ET.SubElement(new_file, f"{{{XLIFF_NS}}}body")
                found_strings = 0
                
                # Process each trans-unit
                for trans_unit in body.findall(f"{{{XLIFF_NS}}}trans-unit"):
                    string_id = trans_unit.get('id', '')
                    
                    # Only include if this string ID is in our target set
                    if string_id in target_ids:
                        # Create a deep copy of the trans-unit
                        new_trans_unit = ET.SubElement(new_body, f"{{{XLIFF_NS}}}trans-unit")
                        
                        # Copy attributes
                        for key, value in trans_unit.attrib.items():
                            new_trans_unit.set(key, value)
                        
                        # Copy all child elements (source, target, note, etc.)
                        for child in trans_unit:
                            new_trans_unit.append(child)
                        
                        found_strings += 1
                
                print(f"  Found {found_strings} matching strings in {file_elem.get('original', 'unknown file')}")
                
                # Remove empty files (files with no matching strings)
                if found_strings == 0:
                    new_root.remove(new_file)
        
        return ET.ElementTree(new_root)
    
    def extract_strings(self, source_xliff_path: str, full_translation_path: str, output_path: str):
        """
        Extract matching strings from full translation file based on source file.
        
        Args:
            source_xliff_path: Path to XLIFF file containing the string IDs to extract
            full_translation_path: Path to full translation XLIFF file
            output_path: Path for the output XLIFF file
        """
        print(f"Loading source file: {source_xliff_path}")
        source_tree = self.parse_xliff(source_xliff_path)
        
        print("Extracting string IDs from source file...")
        target_ids = self.get_string_ids(source_tree)
        print(f"Found {len(target_ids)} string IDs to extract")
        
        print(f"Loading full translation file: {full_translation_path}")
        full_tree = self.parse_xliff(full_translation_path)
        
        print("Extracting matching strings...")
        extracted_tree = self.extract_matching_strings(full_tree, target_ids)
        
        # Create output directory if it doesn't exist
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        
        # Format the XML with proper indentation
        try:
            # Python 3.9+ has indent method
            ET.indent(extracted_tree.getroot(), space="  ", level=0)
        except AttributeError:
            # Fallback for older Python versions using minidom
            import xml.dom.minidom
            rough_string = ET.tostring(extracted_tree.getroot(), encoding='utf-8')
            reparsed = xml.dom.minidom.parseString(rough_string)
            pretty_xml = reparsed.toprettyxml(indent="  ", encoding='utf-8')
            with open(output_path, 'wb') as f:
                f.write(pretty_xml)
            print(f"Saved extracted strings to: {output_path}")
            return
        
        # Write with proper XML declaration and formatting
        with open(output_path, 'wb') as f:
            extracted_tree.write(f, encoding='utf-8', xml_declaration=True)
        
        print(f"Saved extracted strings to: {output_path}")


def main():
    parser = argparse.ArgumentParser(description='Extract matching strings from XLIFF translation files')
    parser.add_argument('source_file', help='Source XLIFF file containing string IDs to extract')
    parser.add_argument('translation_file', help='Full translation XLIFF file to extract from')
    parser.add_argument('output_file', help='Output path for extracted XLIFF file')
    
    args = parser.parse_args()
    
    # Verify input files exist
    if not Path(args.source_file).exists():
        print(f"Error: Source file not found: {args.source_file}")
        sys.exit(1)
    
    if not Path(args.translation_file).exists():
        print(f"Error: Translation file not found: {args.translation_file}")
        sys.exit(1)
    
    # Initialize extractor
    extractor = XLIFFExtractor()
    
    # Extract strings
    try:
        extractor.extract_strings(args.source_file, args.translation_file, args.output_file)
        print("\n✅ Extraction complete!")
    except Exception as e:
        print(f"Error during extraction: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 