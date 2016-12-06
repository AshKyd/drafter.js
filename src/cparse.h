#ifndef CPARSE_H
#define CPARSE_H 1

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int sc_blueprint_parser_options;

/** brief Blueprint Parser Options Enums */
enum sc_blueprint_parser_option {
    SC_RENDER_DESCRIPTIONS_OPTION = (1 << 0),       /// < Render Markdown in description.
    SC_REQUIRE_BLUEPRINT_NAME_OPTION = (1 << 1),    /// < Treat missing blueprint name as error
    SC_EXPORT_SOURCEMAP_OPTION = (1 << 2)           /// < Export source maps AST
};

/** brief Drafter AST Type Option Enum */
enum drafter_ast_type_option {
    DRAFTER_NORMAL_AST_TYPE = 0,      /// < Normal AST
    DRAFTER_REFRACT_AST_TYPE = 1      /// < Refract AST
};

int c_parse(const char* source,
            sc_blueprint_parser_options options,
            enum drafter_ast_type_option astType,
            char** result);

int c_validate(const char *source,
               sc_blueprint_parser_options options,
               char **result);

#ifdef __cplusplus
}
#endif

#endif

