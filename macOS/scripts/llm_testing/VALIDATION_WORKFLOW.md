# LLM Translation Validation Workflow

This guide walks you through the complete process of creating LLM translations, extracting human translations, and generating comparison files for validation studies.

## Prerequisites

### 1. Install Python Dependencies
```bash
pip3 install openai pandas openpyxl
```

### 2. Set OpenAI API Key
```bash
export OPENAI_API_KEY="your-api-key-here"
```

## Step-by-Step Workflow

### Step 0: Export Human Translations (If Needed)

If you need to export human translations from Xcode String Catalogs:

```bash
# Export English (default)
../loc_export.sh

# Export Spanish 
../loc_export.sh es

# Export with custom name
../loc_export.sh es -n export-es
```

This creates `scripts/assets/loc/export-{language}.xliff` which you can then move to `translations_orig/` folder.

### Step 1: Generate LLM Translations

Translate your source XLIFF file using the LLM translation script:

```bash
# For Spanish only
python3 translate_xliff.py assets/loc/random_100_strings.xliff --languages "Spanish" --output-dir ./translations

# For all 24 default languages (will cost ~$1.20-$4.80)
python3 translate_xliff.py assets/loc/random_100_strings.xliff --output-dir ./translations

# For custom languages
python3 translate_xliff.py assets/loc/random_100_strings.xliff --languages "Spanish,French,German" --output-dir ./translations
```

**Output**: `translations/random_100_strings_es-ES.xliff` (LLM translations)

### Step 2: Extract Matching Human Translations

Extract only the strings that were translated by LLM from your full human translation file:

```bash
python3 extract_matching_strings.py assets/loc/random_100_strings.xliff translations_orig/export-es.xliff translations_orig/random_100_strings_es_orig.xliff
```

**Input Files**:
- `assets/loc/random_100_strings.xliff` - Source file with string IDs to extract
- `translations_orig/export-es.xliff` - Full human translation file

**Output**: `translations_orig/random_100_strings_es_orig.xliff` (Human translations for the same strings)

### Step 3: Create Side-by-Side Comparison

Combine LLM and human translations into a single comparison file:

```bash
python3 xliff_compare.py translations/random_100_strings_es-ES.xliff translations_orig/random_100_strings_es_orig.xliff translations/comparison_llm_vs_human_es.xliff
```

**Arguments Order**:
1. LLM translations (will go in `<target>` elements)
2. Human translations (will go in `<target-classic>` elements)
3. Output comparison file

**Output**: `translations/comparison_llm_vs_human_es.xliff` with:
- `<source>` - Original English text
- `<target>` - LLM translation
- `<target-classic>` - Human translation
- `<note>` - Context for evaluators

### Step 4: Generate Excel File for Validation

Create a randomized Excel file for blind evaluation:

```bash
python3 xliff_to_excel.py translations/comparison_llm_vs_human_es.xliff translations/comparison_es.xlsx > mapping_es.txt
```

**Output Files**:
- `translations/comparison_es.xlsx` - Excel file with randomized columns for evaluation
- `mapping_es.txt` - Secret mapping showing which column contains LLM vs Human translations

## File Structure After Completion

```
scripts/llm_testing/
├── translations/
│   ├── random_100_strings_es-ES.xliff      # LLM translations
│   ├── comparison_llm_vs_human_es.xliff    # Side-by-side comparison
│   └── comparison_es.xlsx                  # Excel for validation study
├── translations_orig/
│   ├── export-es.xliff                     # Full human translations
│   └── random_100_strings_es_orig.xliff    # Extracted human translations
└── mapping_es.txt                          # Secret mapping for evaluation
```

## Excel File Format

The generated Excel file contains:
- **Id**: String identifier
- **Original**: English source text
- **First translation**: Randomly assigned (either LLM or Human)
- **Second translation**: Randomly assigned (either Human or LLM)

The `mapping_es.txt` file reveals which column contains which type of translation for analysis after evaluation.

## Validation Study Process

1. **Share Excel file** with evaluators (keep mapping file secret)
2. **Ask evaluators** to rate which translation they prefer for each string
3. **Collect responses** and correlate with the mapping file to determine LLM vs Human preference rates
4. **Analyze results** to understand translation quality patterns

## Key Features

### Brand Protection
The LLM translation script automatically protects DuckDuckGo brand names:
- `Duck Address` → stays as `Duck Address` (never translated)
- `Fire Button` → stays as `Fire Button`
- `Email Protection` → stays as `Email Protection`
- And many more...

### Quality Assurance
- **Proper XLIFF formatting** with newlines and indentation
- **Placeholder preservation** (`%@`, `%d`, `%lld`, etc.)
- **Context preservation** (notes and metadata)
- **Randomized evaluation** to eliminate bias

## Troubleshooting

### Common Issues

**Error: OpenAI API key not provided**
```bash
export OPENAI_API_KEY="your-api-key-here"
```

**Error: No module named 'pandas'**
```bash
pip3 install pandas openpyxl
```

**Error: File not found**
- Check file paths are correct
- Ensure you're in the `scripts/llm_testing` directory

### Cost Management

- **Test with single language first**: `--languages "Spanish"`
- **Use GPT-3.5-turbo**: Default model (cheaper than GPT-4)
- **Adjust batch size**: `--batch-size 5` for slower, cheaper processing

## Language Support

Default supported languages (24 total):
Bulgarian, Croatian, Czech, Danish, Dutch, Estonian, Finnish, French, German, Greek, Hungarian, Italian, Latvian, Lithuanian, Norwegian, Polish, Portuguese, Romanian, Russian, Slovak, Slovenian, Spanish, Swedish, Turkish

## Tips for Success

1. **Start small**: Test with Spanish first before running all languages
2. **Check brand protection**: Verify brand names are preserved in output
3. **Review comparison file**: Manually check a few strings before creating Excel
4. **Keep mapping secret**: Don't share `mapping_*.txt` files until after evaluation
5. **Document everything**: Save copies of all generated files for reproducibility 