#!/usr/bin/env python3
"""
Automated Translation Validation Study Workflow

This script automates the complete workflow for creating translation validation studies:
1. Export human translations from Xcode
2. Generate LLM translations 
3. Extract matching human translations
4. Create comparison file
5. Generate Excel file for validation

Usage: python run_translation_study.py <language_code>
Example: python run_translation_study.py fr
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
import shutil

class TranslationStudyRunner:
    def __init__(self, language_code: str):
        """Initialize the translation study runner."""
        self.language_code = language_code.lower()
        self.working_dir = Path.cwd()
        self.project_root = self.working_dir.parent.parent
        self.scripts_dir = self.working_dir.parent
        
        # Language mapping for full names
        self.language_names = {
            'bg': 'Bulgarian',
            'hr': 'Croatian', 
            'cs': 'Czech',
            'da': 'Danish',
            'nl': 'Dutch',
            'et': 'Estonian',
            'fi': 'Finnish',
            'fr': 'French',
            'de': 'German',
            'el': 'Greek',
            'hu': 'Hungarian',
            'it': 'Italian',
            'lv': 'Latvian',
            'lt': 'Lithuanian',
            'nb': 'Norwegian',
            'pl': 'Polish',
            'pt': 'Portuguese',
            'ro': 'Romanian',
            'ru': 'Russian',
            'sk': 'Slovak',
            'sl': 'Slovenian',
            'es': 'Spanish',
            'sv': 'Swedish',
            'tr': 'Turkish',
        }
        
        # Language codes for XLIFF files  
        self.language_codes = {
            'bg': 'bg-BG',
            'hr': 'hr-HR',
            'cs': 'cs-CZ', 
            'da': 'da-DK',
            'nl': 'nl-NL',
            'et': 'et-EE',
            'fi': 'fi-FI',
            'fr': 'fr-FR',
            'de': 'de-DE',
            'el': 'el-GR',
            'hu': 'hu-HU',
            'it': 'it-IT',
            'lv': 'lv-LV',
            'lt': 'lt-LT',
            'nb': 'nb',
            'pl': 'pl-PL',
            'pt': 'pt-PT',
            'ro': 'ro-RO',
            'ru': 'ru-RU',
            'sk': 'sk-SK',
            'sl': 'sl-SI',
            'es': 'es-ES',
            'sv': 'sv-SE',
            'tr': 'tr-TR',
        }
        
        if self.language_code not in self.language_names:
            raise ValueError(f"Unsupported language code: {language_code}. Supported: {', '.join(self.language_names.keys())}")
            
        self.language_name = self.language_names[self.language_code]
        self.language_full_code = self.language_codes[self.language_code]
        
        # File paths
        self.random_strings_file = self.working_dir / "assets" / "loc" / "random_100_strings.xliff"
        self.human_xliff_file = self.scripts_dir / "assets" / "loc" / f"{self.language_code}.xliff"
        self.llm_translation_file = self.working_dir / "translations" / f"random_100_strings_{self.language_full_code}.xliff"
        self.human_extracted_file = self.working_dir / "translations_orig" / f"random_100_strings_{self.language_code}_orig.xliff"
        self.comparison_file = self.working_dir / "translations" / f"comparison_llm_vs_human_{self.language_code}.xliff"
        self.excel_file = self.working_dir / "translations" / f"comparison_{self.language_code}.xlsx"
        self.mapping_file = self.working_dir / f"mapping_{self.language_code}.txt"

    def print_step(self, step_num: int, description: str):
        """Print a step header."""
        print(f"\n{'='*60}")
        print(f"STEP {step_num}: {description}")
        print(f"{'='*60}")

    def run_command(self, command: list, cwd: Path = None, description: str = ""):
        """Run a shell command and handle errors."""
        if cwd is None:
            cwd = self.working_dir
            
        print(f"🔄 Running: {' '.join(command)}")
        if description:
            print(f"   {description}")
            
        try:
            result = subprocess.run(
                command, 
                cwd=cwd, 
                capture_output=True, 
                text=True, 
                check=True
            )
            if result.stdout:
                print(f"✅ Output: {result.stdout.strip()}")
            return result
        except subprocess.CalledProcessError as e:
            print(f"❌ Error running command: {' '.join(command)}")
            print(f"❌ Exit code: {e.returncode}")
            if e.stdout:
                print(f"❌ Stdout: {e.stdout}")
            if e.stderr:
                print(f"❌ Stderr: {e.stderr}")
            raise

    def check_prerequisites(self):
        """Check that all required files and tools exist."""
        print("🔍 Checking prerequisites...")
        
        # Check API key
        if not os.getenv('OPENAI_API_KEY'):
            print("❌ OPENAI_API_KEY environment variable not set")
            return False
            
        # Check required scripts exist
        required_scripts = [
            self.working_dir / "translate_xliff.py",
            self.working_dir / "extract_matching_strings.py", 
            self.working_dir / "xliff_compare.py",
            self.working_dir / "xliff_to_excel.py",
            self.scripts_dir / "loc_export.sh"
        ]
        
        for script in required_scripts:
            if not script.exists():
                print(f"❌ Required script not found: {script}")
                return False
                
        # Check random strings file exists
        if not self.random_strings_file.exists():
            print(f"❌ Random strings file not found: {self.random_strings_file}")
            return False
            
        print("✅ All prerequisites check passed")
        return True

    def step1_export_human_translations(self):
        """Step 1: Export human translations from Xcode."""
        self.print_step(1, f"Export {self.language_name} Human Translations")
        
        # Run loc_export.sh from project root
        self.run_command(
            ["./scripts/loc_export.sh", self.language_code],
            cwd=self.project_root,
            description=f"Exporting {self.language_name} translations from Xcode"
        )
        
        # Verify the export file was created
        if not self.human_xliff_file.exists():
            raise FileNotFoundError(f"Human translation file not created: {self.human_xliff_file}")
            
        print(f"✅ Human translations exported to: {self.human_xliff_file}")

    def step2_generate_llm_translations(self):
        """Step 2: Generate LLM translations."""
        self.print_step(2, f"Generate {self.language_name} LLM Translations")
        
        # Ensure output directory exists
        self.llm_translation_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Run translation script
        self.run_command(
            [
                "python", "translate_xliff.py",
                str(self.random_strings_file),
                "--languages", self.language_name,
                "--output-dir", "translations"
            ],
            description=f"Generating LLM translations for {self.language_name}"
        )
        
        # Verify the translation file was created
        if not self.llm_translation_file.exists():
            raise FileNotFoundError(f"LLM translation file not created: {self.llm_translation_file}")
            
        print(f"✅ LLM translations generated: {self.llm_translation_file}")

    def step3_extract_matching_human_translations(self):
        """Step 3: Extract matching human translations."""
        self.print_step(3, f"Extract Matching {self.language_name} Human Translations")
        
        # Ensure output directory exists
        self.human_extracted_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Run extraction script
        self.run_command(
            [
                "python", "extract_matching_strings.py",
                str(self.llm_translation_file),
                str(self.human_xliff_file),
                str(self.human_extracted_file)
            ],
            description=f"Extracting matching human translations for {self.language_name}"
        )
        
        # Verify the extracted file was created
        if not self.human_extracted_file.exists():
            raise FileNotFoundError(f"Extracted human translation file not created: {self.human_extracted_file}")
            
        print(f"✅ Matching human translations extracted: {self.human_extracted_file}")

    def step4_create_comparison_file(self):
        """Step 4: Create comparison file."""
        self.print_step(4, f"Create {self.language_name} Comparison File")
        
        # Run comparison script
        self.run_command(
            [
                "python", "xliff_compare.py",
                str(self.llm_translation_file),
                str(self.human_extracted_file),
                str(self.comparison_file)
            ],
            description=f"Creating comparison file for {self.language_name}"
        )
        
        # Verify the comparison file was created
        if not self.comparison_file.exists():
            raise FileNotFoundError(f"Comparison file not created: {self.comparison_file}")
            
        print(f"✅ Comparison file created: {self.comparison_file}")

    def step5_generate_excel_file(self):
        """Step 5: Generate Excel file for validation."""
        self.print_step(5, f"Generate {self.language_name} Excel Validation File")
        
        # Run Excel generation script and capture mapping output
        result = self.run_command(
            [
                "python", "xliff_to_excel.py",
                str(self.comparison_file),
                str(self.excel_file)
            ],
            description=f"Generating Excel validation file for {self.language_name}"
        )
        
        # Save mapping output to file
        if result.stdout:
            with open(self.mapping_file, 'w', encoding='utf-8') as f:
                f.write(result.stdout)
            print(f"✅ Mapping information saved: {self.mapping_file}")
        
        # Verify the Excel file was created
        if not self.excel_file.exists():
            raise FileNotFoundError(f"Excel file not created: {self.excel_file}")
            
        print(f"✅ Excel validation file created: {self.excel_file}")

    def print_summary(self):
        """Print summary of generated files."""
        print(f"\n{'='*60}")
        print(f"🎉 TRANSLATION VALIDATION STUDY COMPLETE!")
        print(f"Language: {self.language_name} ({self.language_code})")
        print(f"{'='*60}")
        
        print(f"\n📁 Generated Files:")
        print(f"  🤖 LLM Translations:     {self.llm_translation_file}")
        print(f"  👥 Human Translations:   {self.human_extracted_file}")
        print(f"  🔄 Comparison File:      {self.comparison_file}")
        print(f"  📊 Excel Validation:     {self.excel_file}")
        print(f"  🗺️  Mapping Key:          {self.mapping_file}")
        
        print(f"\n🚀 Next Steps:")
        print(f"  1. Open '{self.excel_file}' for validation")
        print(f"  2. Evaluate translation quality in randomized columns")
        print(f"  3. Use '{self.mapping_file}' to reveal which column is LLM vs Human")
        print(f"  4. Analyze results to assess LLM translation quality")

    def run(self):
        """Run the complete translation validation study workflow."""
        try:
            print(f"🌍 Starting Translation Validation Study for {self.language_name} ({self.language_code})")
            
            # Check prerequisites
            if not self.check_prerequisites():
                sys.exit(1)
            
            # Run all steps
            self.step1_export_human_translations()
            self.step2_generate_llm_translations()
            self.step3_extract_matching_human_translations()
            self.step4_create_comparison_file()
            self.step5_generate_excel_file()
            
            # Print summary
            self.print_summary()
            
        except Exception as e:
            print(f"\n❌ WORKFLOW FAILED: {e}")
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description='Run complete translation validation study workflow',
        epilog='''
Examples:
  python run_translation_study.py fr    # French validation study
  python run_translation_study.py es    # Spanish validation study
  python run_translation_study.py de    # German validation study

Supported language codes:
  bg (Bulgarian), hr (Croatian), cs (Czech), da (Danish), nl (Dutch),
  et (Estonian), fi (Finnish), fr (French), de (German), el (Greek),
  hu (Hungarian), it (Italian), lv (Latvian), lt (Lithuanian), 
  nb (Norwegian), pl (Polish), pt (Portuguese), ro (Romanian),
  ru (Russian), sk (Slovak), sl (Slovenian), es (Spanish),
  sv (Swedish), tr (Turkish)
        ''',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        'language_code',
        help='Language code (e.g., fr, es, de)'
    )
    
    args = parser.parse_args()
    
    try:
        runner = TranslationStudyRunner(args.language_code)
        runner.run()
    except ValueError as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 