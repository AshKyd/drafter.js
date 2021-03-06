#include "cparse.h"

#include "snowcrash.h"
#include "drafter_private.h"
#include "sosJSON.h"

#include "SerializeAST.h"
#include "SerializeSourcemap.h"
#include "SerializeResult.h"

#include "ConversionContext.h"

#include <string.h>

namespace sc = snowcrash;

static char* ToString(const std::stringstream& stream)
{
    size_t length = stream.str().length() + 1;
    char* str = (char*)malloc(length);
    memcpy(str, stream.str().c_str(), length);
    return str;
}

int c_parse(const char* source,
                   sc_blueprint_parser_options options,
                   char** result)
{

    std::stringstream inputStream;

    inputStream << source;

    sc::ParseResult<sc::Blueprint> blueprint;
    sc::parse(inputStream.str(), options | sc::ExportSourcemapOption, blueprint);

    sos::SerializeJSON serializer;

    if (result) {
        std::stringstream resultStream;
        drafter::WrapperOptions wrapperOptions(drafter::RefractASTType, options & SC_EXPORT_SOURCEMAP_OPTION);

        try {
            serializer.process(drafter::WrapResult(blueprint, wrapperOptions), resultStream);
        }
        catch (snowcrash::Error& e) {
            blueprint.report.error = e;
        }
        catch (std::exception& e) {
            blueprint.report.error = snowcrash::Error(e.what(), snowcrash::ApplicationError);
        }

        resultStream << "\n";
        *result = ToString(resultStream);
    }

    return blueprint.report.error.code;
}

int c_validate(const char *source,
                      sc_blueprint_parser_options options,
                      char **result)
{
    drafter_result *res = NULL;
    drafter_parse_options parse_opts;
    parse_opts.requireBlueprintName = (bool)(options & SC_REQUIRE_BLUEPRINT_NAME_OPTION);

    res = drafter_check_blueprint_with_options(source, parse_opts);

    if (NULL != res) {
        *result = drafter_serialize(res,
                                    (drafter_options){false, DRAFTER_SERIALIZE_JSON});
        drafter_free_result(res);
        return 1;
    }

    return 0;
}
