#include <vector>
#include <tree_sitter/parser.h>

enum TokenType
{
    here_string_terminator,
};


extern "C" void * tree_sitter_jai_external_scanner_create() 
{
  return nullptr;
}

extern "C" void tree_sitter_jai_external_scanner_destroy(void *payload) {
 
}

extern "C" unsigned tree_sitter_jai_external_scanner_serialize(void *payload, char *buffer) 
{
    return 0;
}

extern "C" void tree_sitter_jai_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
  
}

static bool IsWhitespace(int32_t character)
{
    return character == ' ' || character ==  '\t' || character == '\r' || character == '\n';
}

extern "C" bool tree_sitter_jai_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) 
{
    if (!valid_symbols[here_string_terminator])
        return false;

    if (lexer->eof(lexer))
    {
        return false;
    }

    // always one character of whitespace.
    while ( IsWhitespace(lexer->lookahead) )
    {
        lexer->advance(lexer, true);

        if (lexer->eof(lexer))
        {
            return false;
        }
    }

    std::vector<int32_t> terminator;

    while (!IsWhitespace(lexer->lookahead))
    {
        terminator.push_back(lexer->lookahead);
        
        lexer->advance(lexer, false);
        if (lexer->eof(lexer))
        {
            return false;
        }
    }
  
    /*
    lexer->advance(lexer, false);
    lexer->advance(lexer, false);
    lexer->advance(lexer, false);
    lexer->advance(lexer, false);


    terminator.push_back('D');
    terminator.push_back('O');
    terminator.push_back('N');
    terminator.push_back('E');
    */

    int matchCursor = 0;
    // now match the terminator
    while (!lexer->eof(lexer))
    {
        if (lexer->lookahead == terminator[matchCursor])
        {
            matchCursor++;
        }
        else
        {
            matchCursor = 0;
        }

        if (matchCursor == terminator.size())
        {
            lexer->advance(lexer, false);
            lexer->mark_end(lexer);
            lexer->result_symbol = here_string_terminator;
            return true;
        }

        lexer->advance(lexer, false);
    }

    // eof
    return false;
}