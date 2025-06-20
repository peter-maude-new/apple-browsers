#!/usr/bin/env python3
"""
XLIFF Translation Script using OpenAI API

This script reads an XLIFF file containing source strings in English,
translates them to target languages using OpenAI's API, and outputs
properly formatted XLIFF files for each target language.
"""

import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
import openai
import time
import argparse
from typing import List, Dict, Tuple
import json

# XLIFF namespace
XLIFF_NS = "urn:oasis:names:tc:xliff:document:1.2"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"

# Register namespaces
ET.register_namespace('', XLIFF_NS)
ET.register_namespace('xsi', XSI_NS)

class XLIFFTranslator:
    def __init__(self, api_key: str, model: str = "gpt-3.5-turbo"):
        """Initialize the translator with OpenAI API key and model."""
        self.client = openai.OpenAI(api_key=api_key)
        self.model = model
        
        # Language code mapping
        self.language_codes = {
            'Bulgarian': 'bg-BG',
            'Croatian': 'hr-HR',
            'Czech': 'cs-CZ',
            'Danish': 'da-DK',
            'Dutch': 'nl-NL',
            'Estonian': 'et-EE',
            'Finnish': 'fi-FI',
            'French': 'fr-FR',
            'German': 'de-DE',
            'Greek': 'el-GR',
            'Hungarian': 'hu-HU',
            'Italian': 'it-IT',
            'Latvian': 'lv-LV',
            'Lithuanian': 'lt-LT',
            'Norwegian': 'nb',
            'Polish': 'pl-PL',
            'Portuguese': 'pt-PT',
            'Romanian': 'ro-RO',
            'Russian': 'ru-RU',
            'Slovak': 'sk-SK',
            'Slovenian': 'sl-SI',
            'Spanish': 'es-ES',
            'Swedish': 'sv-SE',
            'Turkish': 'tr-TR',
        }
    
    def _get_language_code(self, language_name: str) -> str:
        """Get the ISO language code for a language name."""
        return self.language_codes.get(language_name, language_name.lower())
        
    def translate_single_string(self, string_id: str, text: str, target_language: str, source_language: str = "English") -> str:
        """
        Translate a single string to the target language.
        
        Args:
            string_id: Identifier for the string
            text: Text to translate
            target_language: Target language name
            source_language: Source language name
            
        Returns:
            Translated text or None if translation failed
        """
        
        # Extract language code from target_language parameter
        target_lang_code = self._get_language_code(target_language)
        
        # Generate appropriate examples for the target language
        examples = self._generate_brand_examples(target_language)
        
        prompt = f"""You are a professional translator designated to translate text for a desktop app from {source_language} to {target_language} (ISO 639-1 code "{target_lang_code}"). 

Input text may contain Swift argument placeholders (%arg, @arg1, %lld, %@, %d, etc) and it's important they are preserved in the translated text. Trim extra spaces at the beginning and end of the translated text. Do not provide blank translations. Do not hallucinate. Do not provide translations that are not faithful to the original text. 

Pay attention to capitalised words in the middle of a sentence as they usually refer to feature names. Translate features' names when they don't belong to the list of names not to translate, but maintain proper capitalisation. It's possible that some strings are single word. If the word can be translated in different ways in the target language and you don't have enough context to pick one, please still provide your best translation.

Strings are for DuckDuckGo apps. DuckDuckGo makes tools that help people protect their privacy online. DuckDuckGo's products include:
- DuckDuckGo Private Search, a private search engine.
- DuckDuckGo Privacy Essentials, browser extensions that block online trackers.
- Web browser with built-in tracking protection and other privacy features for iOS, Android, and macOS.
- Email Protection, an email service that removes trackers from email a user receives.
- App Tracking Protection, a feature within our Android browser that blocks tracking that occurs within other apps a user has installed on their phone.

Broadly, safe to assume our largest audience is a mainstream audience 18+; Tech-aware but not tech-experts. Tone is casual and friendly. Try to write as though we're talking to another person, and use plain, easily-understandable language. Second person pronoun ("you") should be informal where appropriate for {target_language}. Colloquial expressions are generally appropriate. Encourage the use of Active Voice. Abbreviations are not acceptable.

CRITICAL: Do not translate ANY branded names, Email addresses and Urls. Brand names must ALWAYS remain in English, regardless of context.

NEVER TRANSLATE these specific brand names: "DuckDuckGo", "Duck Address", "Private Duck Address", "Private Search", "Tracker Radar", "Smarter Encryption", "Email Protection", "App Tracking Protection", "Fire Button", "Global Privacy Control", "Cloud Save", "Duck Player", "Privacy Pro", "Fireproof".

IMPORTANT: "Duck Address" is a product name and must NEVER be translated. Even when it appears with other words like "Private Duck Address" or "Deactivate Duck Address", the "Duck Address" part must remain unchanged.

CRITICAL: "Fireproof" is a DuckDuckGo feature name and must NEVER be translated in any form or case:
- As a noun: "Fireproof" stays "Fireproof"  
- As a verb: "Fireproof this site" stays "Fireproof this site"
- As an adjective: "make it fireproof" stays "make it fireproof" (keep "fireproof" even when lowercase)
- In questions: "Would you like to Fireproof %@?" keeps "Fireproof" unchanged
- Case-insensitive: Both "Fireproof" and "fireproof" must remain unchanged

{examples}

Do NOT translate these as variations like "Dirección de Correo", "Botón de Fuego", "Protección de Correo", "ignifuge", "à l'épreuve du feu", etc.

Preserve title case and use correct grammar. Prioritize idiomaticity and relative string length. Do not translate the brand name "DuckDuckGo" or other brand names, e.g. "Safari," "Firefox". Do not mix formal and informal tone. Do not localize phone numbers or mailing addresses.

Please translate the following text and return ONLY the translated text, nothing else:

{text}
"""

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a professional software translator. Return only the translated text."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1,
                max_tokens=1000
            )
            
            translated_text = response.choices[0].message.content.strip()
            
            # Remove any quotes that might wrap the translation
            if translated_text.startswith('"') and translated_text.endswith('"'):
                translated_text = translated_text[1:-1]
            if translated_text.startswith("'") and translated_text.endswith("'"):
                translated_text = translated_text[1:-1]
                
            return translated_text
                
        except Exception as e:
            print(f"  ❌ Error translating string '{string_id}': {e}")
            return None
    
    def _generate_brand_examples(self, target_language: str) -> str:
        """Generate brand protection examples in the target language."""
        
        # Language-specific example translations (keeping brand names in English)
        language_examples = {
            'French': {
                'deactivate': 'Désactiver Private Duck Address?',
                'ready': 'Votre Duck Address est prêt',
                'clears': 'Fire Button efface les données',
                'enable': 'Activer Email Protection',
                'fireproof': 'Souhaitez-vous Fireproof ce site ?',
                'fireproof_lower': 'Rendez-le fireproof'
            },
            'German': {
                'deactivate': 'Private Duck Address deaktivieren?',
                'ready': 'Ihr Duck Address ist bereit',
                'clears': 'Fire Button löscht Daten',
                'enable': 'Email Protection aktivieren',
                'fireproof': 'Möchten Sie diese Seite Fireproof machen?',
                'fireproof_lower': 'Machen Sie es fireproof'
            },
            'Spanish': {
                'deactivate': 'Desactivar Private Duck Address?',
                'ready': 'Tu Duck Address está listo',
                'clears': 'Fire Button borra los datos',
                'enable': 'Activar Email Protection',
                'fireproof': '¿Te gustaría hacer Fireproof este sitio?',
                'fireproof_lower': 'Hazlo fireproof'
            },
            'Italian': {
                'deactivate': 'Disattivare Private Duck Address?',
                'ready': 'Il tuo Duck Address è pronto',
                'clears': 'Fire Button cancella i dati',
                'enable': 'Attivare Email Protection',
                'fireproof': 'Vuoi rendere Fireproof questo sito?',
                'fireproof_lower': 'Rendilo fireproof'
            },
            'Portuguese': {
                'deactivate': 'Desativar Private Duck Address?',
                'ready': 'Seu Duck Address está pronto',
                'clears': 'Fire Button limpa dados',
                'enable': 'Ativar Email Protection',
                'fireproof': 'Gostaria de tornar este site Fireproof?',
                'fireproof_lower': 'Torne-o fireproof'
            },
            'Dutch': {
                'deactivate': 'Private Duck Address deactiveren?',
                'ready': 'Je Duck Address is klaar',
                'clears': 'Fire Button wist gegevens',
                'enable': 'Email Protection inschakelen',
                'fireproof': 'Wil je deze site Fireproof maken?',
                'fireproof_lower': 'Maak het fireproof'
            },
            'Polish': {
                'deactivate': 'Dezaktywować Private Duck Address?',
                'ready': 'Twój Duck Address jest gotowy',
                'clears': 'Fire Button czyści dane',
                'enable': 'Włączyć Email Protection',
                'fireproof': 'Czy chcesz Fireproof tę stronę?',
                'fireproof_lower': 'Uczynić to fireproof'
            },
            'Russian': {
                'deactivate': 'Отключить Private Duck Address?',
                'ready': 'Ваш Duck Address готов',
                'clears': 'Fire Button очищает данные',
                'enable': 'Включить Email Protection',
                'fireproof': 'Хотите сделать этот сайт Fireproof?',
                'fireproof_lower': 'Сделать его fireproof'
            },
            'Czech': {
                'deactivate': 'Deaktivovat Private Duck Address?',
                'ready': 'Váš Duck Address je připraven',
                'clears': 'Fire Button maže data',
                'enable': 'Aktivovat Email Protection',
                'fireproof': 'Chcete tento web Fireproof?',
                'fireproof_lower': 'Učinit to fireproof'
            },
            'Slovak': {
                'deactivate': 'Deaktivovať Private Duck Address?',
                'ready': 'Váš Duck Address je pripravený',
                'clears': 'Fire Button maže údaje',
                'enable': 'Aktivovať Email Protection',
                'fireproof': 'Chcete tento web Fireproof?',
                'fireproof_lower': 'Urobiť to fireproof'
            }
        }
        
        # Get examples for the target language, fallback to generic examples
        if target_language in language_examples:
            examples = language_examples[target_language]
            
            return f"""Examples of CORRECT brand handling in {target_language}:
- "Deactivate Private Duck Address?" → "{examples['deactivate']}" (keep "Duck Address" in English)
- "Your Duck Address is ready" → "{examples['ready']}" (keep "Duck Address" in English)
- "Fire Button clears data" → "{examples['clears']}" (keep "Fire Button" in English)
- "Enable Email Protection" → "{examples['enable']}" (keep "Email Protection" in English)
- "Fireproof" → "{examples['fireproof']}" (keep "Fireproof" in English)
- "Make it fireproof" → "{examples['fireproof_lower']}" (keep "fireproof" in English even when lowercase)"""
        else:
            # Generic examples for unsupported languages
            return f"""Examples of CORRECT brand handling:
- Keep "Duck Address" unchanged: "Deactivate Private Duck Address?" → "[Translate 'Deactivate'] Private Duck Address?"
- Keep "Fire Button" unchanged: "Fire Button clears data" → "Fire Button [translate 'clears data']"
- Keep "Email Protection" unchanged: "Enable Email Protection" → "[Translate 'Enable'] Email Protection"
- Keep "Fireproof" unchanged: "Would you like to Fireproof this site?" → "[Translate 'Would you like to'] Fireproof [translate 'this site']?"
- Keep "DuckDuckGo" unchanged: "DuckDuckGo VPN" → "DuckDuckGo VPN" """
    
    def parse_xliff(self, xliff_path: str) -> ET.ElementTree:
        """Parse the XLIFF file and return the ElementTree."""
        try:
            tree = ET.parse(xliff_path)
            return tree
        except ET.ParseError as e:
            print(f"Error parsing XLIFF file: {e}")
            sys.exit(1)
    
    def extract_strings(self, tree: ET.ElementTree) -> List[Tuple[str, str, str]]:
        """
        Extract translatable strings from XLIFF.
        
        Returns:
            List of (string_id, source_text, note) tuples
        """
        root = tree.getroot()
        strings = []
        
        # Find all trans-unit elements
        for trans_unit in root.findall(f".//{{{XLIFF_NS}}}trans-unit"):
            string_id = trans_unit.get('id', '')
            
            source_elem = trans_unit.find(f"{{{XLIFF_NS}}}source")
            source_text = source_elem.text if source_elem is not None and source_elem.text else ''
            
            note_elem = trans_unit.find(f"{{{XLIFF_NS}}}note")
            note_text = note_elem.text if note_elem is not None and note_elem.text else ''
            
            if source_text.strip():  # Only include non-empty strings
                strings.append((string_id, source_text, note_text))
        
        return strings
    
    def create_translated_xliff(self, original_tree: ET.ElementTree, translations: Dict[str, str], 
                              target_language: str, target_language_code: str) -> ET.ElementTree:
        """
        Create a new XLIFF tree with translations.
        
        Args:
            original_tree: Original XLIFF tree
            translations: Dictionary mapping string_id to translated text
            target_language: Full language name
            target_language_code: Language code (e.g., 'es', 'fr')
            
        Returns:
            New ElementTree with translations
        """
        # Create a deep copy of the original tree
        root = original_tree.getroot()
        new_root = ET.Element(root.tag, root.attrib)
        
        # Copy all attributes and namespace declarations
        for key, value in root.attrib.items():
            new_root.set(key, value)
        
        # Process each file element
        for file_elem in root.findall(f"{{{XLIFF_NS}}}file"):
            new_file = ET.SubElement(new_root, f"{{{XLIFF_NS}}}file")
            
            # Copy file attributes but update target-language
            for key, value in file_elem.attrib.items():
                if key == 'target-language':
                    new_file.set(key, target_language_code)
                else:
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
                
                # Process each trans-unit
                for trans_unit in body.findall(f"{{{XLIFF_NS}}}trans-unit"):
                    new_trans_unit = ET.SubElement(new_body, f"{{{XLIFF_NS}}}trans-unit")
                    
                    # Copy attributes
                    for key, value in trans_unit.attrib.items():
                        new_trans_unit.set(key, value)
                    
                    string_id = trans_unit.get('id', '')
                    
                    # Copy source
                    source_elem = trans_unit.find(f"{{{XLIFF_NS}}}source")
                    if source_elem is not None:
                        new_source = ET.SubElement(new_trans_unit, f"{{{XLIFF_NS}}}source")
                        new_source.text = source_elem.text
                        for key, value in source_elem.attrib.items():
                            new_source.set(key, value)
                    
                    # Create target with translation
                    new_target = ET.SubElement(new_trans_unit, f"{{{XLIFF_NS}}}target")
                    if string_id in translations and translations[string_id] is not None:
                        new_target.text = translations[string_id]
                        new_target.set('state', 'translated')
                    else:
                        # Fallback to source text if translation not found
                        new_target.text = source_elem.text if source_elem is not None else ''
                        new_target.set('state', 'new')
                    
                    # Copy note
                    note_elem = trans_unit.find(f"{{{XLIFF_NS}}}note")
                    if note_elem is not None:
                        new_note = ET.SubElement(new_trans_unit, f"{{{XLIFF_NS}}}note")
                        new_note.text = note_elem.text
                        for key, value in note_elem.attrib.items():
                            new_note.set(key, value)
        
        return ET.ElementTree(new_root)
    
    def translate_xliff(self, input_path: str, output_dir: str, target_languages: Dict[str, str]):
        """
        Translate an XLIFF file to multiple target languages.
        
        Args:
            input_path: Path to input XLIFF file
            output_dir: Directory to save translated XLIFF files
            target_languages: Dict mapping language codes to language names
        """
        print(f"Loading XLIFF file: {input_path}")
        tree = self.parse_xliff(input_path)
        
        print("Extracting strings...")
        strings = self.extract_strings(tree)
        print(f"Found {len(strings)} strings to translate")
        
        # Create output directory
        Path(output_dir).mkdir(parents=True, exist_ok=True)
        
        for lang_code, lang_name in target_languages.items():
            print(f"\nTranslating to {lang_name} ({lang_code})...")
            
            all_translations = {}
            successful_count = 0
            failed_count = 0
            
            # Process strings individually
            for i, (string_id, source_text, note_text) in enumerate(strings, 1):
                print(f"  [{i:3}/{len(strings)}] Translating: {string_id[:50]}{'...' if len(string_id) > 50 else ''}")
                
                translated_text = self.translate_single_string(string_id, source_text, lang_name)
                
                if translated_text is not None and translated_text.strip():
                    all_translations[string_id] = translated_text
                    successful_count += 1
                    print(f"  ✅ Success: {translated_text[:60]}{'...' if len(translated_text) > 60 else ''}")
                else:
                    failed_count += 1
                    print(f"  ❌ Failed: {string_id}")
                
                # Rate limiting - wait between API calls
                if i < len(strings):
                    time.sleep(0.5)  # 500ms between calls to avoid rate limits
            
            print(f"\n📊 Translation Results for {lang_name}:")
            print(f"  ✅ Successfully translated: {successful_count}/{len(strings)} strings ({successful_count/len(strings)*100:.1f}%)")
            print(f"  ❌ Failed translations: {failed_count}/{len(strings)} strings ({failed_count/len(strings)*100:.1f}%)")
            
            # Create translated XLIFF
            translated_tree = self.create_translated_xliff(tree, all_translations, lang_name, lang_code)
            
            # Save translated XLIFF
            input_filename = Path(input_path).stem
            output_path = Path(output_dir) / f"{input_filename}_{lang_code}.xliff"
            
            # Format the XML with proper indentation
            try:
                # Python 3.9+ has indent method
                ET.indent(translated_tree.getroot(), space="  ", level=0)
            except AttributeError:
                # Fallback for older Python versions using minidom
                import xml.dom.minidom
                rough_string = ET.tostring(translated_tree.getroot(), encoding='utf-8')
                reparsed = xml.dom.minidom.parseString(rough_string)
                pretty_xml = reparsed.toprettyxml(indent="  ", encoding='utf-8')
                with open(output_path, 'wb') as f:
                    f.write(pretty_xml)
                print(f"  💾 Saved: {output_path}")
                continue
            
            # Write with proper XML declaration and formatting
            with open(output_path, 'wb') as f:
                translated_tree.write(f, encoding='utf-8', xml_declaration=True)
            
            print(f"  💾 Saved: {output_path}")


def main():
    parser = argparse.ArgumentParser(description='Translate XLIFF files using OpenAI API')
    parser.add_argument('input_file', help='Input XLIFF file path')
    parser.add_argument('--output-dir', '-o', default='./translations', 
                        help='Output directory for translated files (default: ./translations)')
    parser.add_argument('--api-key', help='OpenAI API key (or set OPENAI_API_KEY env var)')
    parser.add_argument('--model', default='gpt-3.5-turbo', help='OpenAI model to use (default: gpt-3.5-turbo)')
    parser.add_argument('--languages', default='bg-BG:Bulgarian,hr-HR:Croatian,cs-CZ:Czech,da-DK:Danish,nl-NL:Dutch,et-EE:Estonian,fi-FI:Finnish,fr-FR:French,de-DE:German,el-GR:Greek,hu-HU:Hungarian,it-IT:Italian,lv-LV:Latvian,lt-LT:Lithuanian,nb:Norwegian,pl-PL:Polish,pt-PT:Portuguese,ro-RO:Romanian,ru-RU:Russian,sk-SK:Slovak,sl-SI:Slovenian,es-ES:Spanish,sv-SE:Swedish,tr-TR:Turkish',
                        help='Target languages. Supports: language names (Spanish,French), codes (es-ES,fr-FR), or code:name pairs')
    
    args = parser.parse_args()
    
    # Get API key
    api_key = args.api_key or os.getenv('OPENAI_API_KEY')
    if not api_key:
        print("Error: OpenAI API key not provided. Use --api-key or set OPENAI_API_KEY environment variable.")
        sys.exit(1)
    
    # Parse target languages - support multiple formats:
    # 1. "code:name" format (backward compatibility)
    # 2. Just language names: "Spanish,French,German"  
    # 3. Just language codes: "es-ES,fr-FR,de-DE"
    translator = XLIFFTranslator(api_key, args.model)  # Create early to access language_codes
    target_languages = {}
    
    for lang_item in args.languages.split(','):
        lang_item = lang_item.strip()
        
        if ':' in lang_item:
            # Format: "code:name"
            code, name = lang_item.split(':', 1)
            target_languages[code.strip()] = name.strip()
        elif lang_item in translator.language_codes:
            # Format: just language name
            target_languages[translator.language_codes[lang_item]] = lang_item
        else:
            # Check if it's a language code
            reverse_mapping = {v: k for k, v in translator.language_codes.items()}
            if lang_item in reverse_mapping:
                # Format: just language code
                target_languages[lang_item] = reverse_mapping[lang_item]
            else:
                print(f"Warning: Unknown language '{lang_item}', skipping...")
    
    if not target_languages:
        print("Error: No valid target languages specified.")
        sys.exit(1)
    
    print(f"Target languages: {target_languages}")
    
    # Translate
    try:
        translator.translate_xliff(args.input_file, args.output_dir, target_languages)
        print(f"\n🎉 Translation complete! Files saved in: {args.output_dir}")
    except KeyboardInterrupt:
        print("\nTranslation interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"Error during translation: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 