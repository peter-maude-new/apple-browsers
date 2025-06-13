# XLIFF Translation Script

This script translates XLIFF files using OpenAI's API, specifically designed for software localization workflows.

## Setup

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Set your OpenAI API key as an environment variable:
```bash
export OPENAI_API_KEY="your-api-key-here"
```

Alternatively, you can pass the API key directly to the script using the `--api-key` parameter.

## Usage

### Basic Usage

```bash
python translate_xliff.py assets/loc/random_100_strings.xliff
```

This will translate your XLIFF file to the default set of 24 European languages (Bulgarian, Croatian, Czech, Danish, Dutch, Estonian, Finnish, French, German, Greek, Hungarian, Italian, Latvian, Lithuanian, Norwegian, Polish, Portuguese, Romanian, Russian, Slovak, Slovenian, Spanish, Swedish, Turkish) and save the results in a `./translations` directory.

### Custom Options

```bash
# Using language names (simplest)
python translate_xliff.py assets/loc/random_100_strings.xliff \
    --output-dir ./my_translations \
    --languages "Spanish,French,German" \
    --batch-size 5 \
    --model gpt-4

# Using language codes
python translate_xliff.py assets/loc/random_100_strings.xliff \
    --languages "es-ES,fr-FR,de-DE"

# Using code:name pairs (backward compatibility)
python translate_xliff.py assets/loc/random_100_strings.xliff \
    --languages "es-ES:Spanish,fr-FR:French,de-DE:German"
```

### Command Line Options

- `input_file`: Path to the input XLIFF file (required)
- `--output-dir, -o`: Output directory for translated files (default: `./translations`)
- `--api-key`: OpenAI API key (alternatively set `OPENAI_API_KEY` environment variable)
- `--model`: OpenAI model to use (default: `gpt-3.5-turbo`, can use `gpt-4` for higher quality)
- `--batch-size`: Number of strings to translate per API call (default: 10, lower for cost control)
- `--languages`: Target languages. Supports language names (`Spanish,French`), codes (`es-ES,fr-FR`), or `code:name` pairs

### Language Codes

The script uses standard language codes. The default supported languages are:
- `bg-BG`: Bulgarian
- `hr-HR`: Croatian
- `cs-CZ`: Czech
- `da-DK`: Danish
- `nl-NL`: Dutch
- `et-EE`: Estonian
- `fi-FI`: Finnish
- `fr-FR`: French
- `de-DE`: German
- `el-GR`: Greek
- `hu-HU`: Hungarian
- `it-IT`: Italian
- `lv-LV`: Latvian
- `lt-LT`: Lithuanian
- `nb`: Norwegian
- `pl-PL`: Polish
- `pt-PT`: Portuguese
- `ro-RO`: Romanian
- `ru-RU`: Russian
- `sk-SK`: Slovak
- `sl-SI`: Slovenian
- `es-ES`: Spanish
- `sv-SE`: Swedish
- `tr-TR`: Turkish

## Output

The script will create translated XLIFF files in the specified output directory with the naming pattern:
`{original_filename}_{language_code}.xliff`

For example:
- `random_100_strings_es-ES.xliff` (Spanish)
- `random_100_strings_fr-FR.xliff` (French)
- `random_100_strings_de-DE.xliff` (German)
- `random_100_strings_bg-BG.xliff` (Bulgarian)
- `random_100_strings_hr-HR.xliff` (Croatian)
- etc.

## Features

- **Preserves XLIFF structure**: Maintains all original metadata, notes, and file structure
- **Batch processing**: Translates multiple strings at once for efficiency
- **Rate limiting**: Includes delays between API calls to respect rate limits
- **Error handling**: Robust error handling for API failures and malformed responses
- **Context-aware**: Includes string context (notes) to improve translation quality
- **Enhanced DuckDuckGo-specific prompt**: Uses proven translation guidelines with:
  - Swift placeholder preservation (`%@`, `%d`, `%lld`, etc.)
  - DuckDuckGo product context and brand guidelines
  - Casual, friendly tone matching DuckDuckGo's voice
  - Comprehensive list of protected brand names
  - Feature name translation guidelines
- **Brand name preservation**: Comprehensive protection for DuckDuckGo products including Duck Address, Privacy Pro, Duck Player, Fire Button, etc.

## Cost Estimation

Using GPT-3.5-turbo (default):
- ~100 strings with context: approximately $0.05-$0.20 per language
- For all 24 default languages: approximately $1.20-$4.80 total

Using GPT-4 (higher quality):
- ~100 strings with context: approximately $0.50-$2.00 per language
- For all 24 default languages: approximately $12-$48 total

Batch size affects cost efficiency - larger batches are more cost-effective but may hit token limits.

## Notes

- The script uses an enhanced prompt based on proven DuckDuckGo translation workflows
- The script sets target state to "translated" for successfully translated strings
- If a translation fails, the target falls back to the source text with state "new"
- All original XLIFF metadata and structure is preserved
- The script handles XLIFF 1.2 format with proper namespacing
- Swift/iOS placeholders and DuckDuckGo brand names (Duck Address, Privacy Pro, Duck Player, etc.) are automatically protected 