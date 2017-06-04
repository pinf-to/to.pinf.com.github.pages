
const PATH = require("path");
const FS = require("fs-extra");
const LODASH = require("lodash");
const CODEBLOCK = require("codeblock");
const ESCAPE_REGEXP = require("escape-regexp");

const MARKED = require("marked");
const HIGHLIGHT = require("highlight.js");

const VERBOSE = !!process.env.VERBOSE;



exports.replaceVariablesInCode = function (variables, code) {

    // Trim lines
    code = code.split("\n").filter(function (line) {
        var m = line.match(/^\[IF:%%%([\w_]+?)%%%\]/);
        if (m) {
            if (!variables[m[1]]) {
                return false;
            }
        }
        return true;
    }).map(function (line) {
        line = line.replace(/^\[IF:%%%([\w_]+?)%%%\]/, "");

        // Replace all variables
        function iterate () {
            var re = /%%%([\w_]+?)%%%/g;
            var match;
            while ( (match = re.exec(line)) ) {

                if (typeof variables[match[1]] === "undefined") {
                    throw new Error("Variable with name '" + match[1] + "' not declared!");

                }

                line = line.replace(
                    new RegExp(ESCAPE_REGEXP(match[0]), "g"),
                    variables[match[1]]
                );
            }                    
        }

        iterate();
        // NOTE: For some reason 'PACKAGE_LICENSE_URL' will not get replaced the first time.
        //       Maybe because the new string is smaller than the old one.
        iterate();

        return line;
    }).join("\n");

    code = code.replace(/&#96;/g, "`");

    return code;
}


exports.publish = function (sourceBasePath, config, options) {

    const BOILERPLATE = options.BOILERPLATE;

    // TODO: Relocate into JSON utility module
    if (config["-<"]) {
        if (
            config["-<"]["merge()"] &&
            config["-<"]["merge()"][".@"] === "github.com~0ink~codeblock/codeblock:Codeblock"
        ) {
            config["-<"] = CODEBLOCK.run(config["-<"]["merge()"], config["-<"], {
                sandbox: {
                    require: require,
                    process: process
                }
            });
        }
        // TODO: Use more powerful merge
        config = LODASH.merge({}, config, config["-<"]);
        delete config["-<"];
    }

    if (VERBOSE) console.log("config:", config);

    if (VERBOSE) console.log("config.cd:", config.cd);

    var uriDepth = 0;
    if (config.cd) {
        uriDepth = config.cd.split("/").length;
        var path = PATH.join(process.cwd(), config.cd);
        if (!FS.existsSync(path)) {
            FS.mkdirsSync(path);
        }

        if (VERBOSE) console.log("uriDepth:", uriDepth);
        if (VERBOSE) console.log("path:", path);

        process.chdir(path);
        sourceBasePath = sourceBasePath + "/" + config.cd;
    }

    if (VERBOSE) console.log("sourceBasePath:", sourceBasePath);

    if (VERBOSE) console.log("cwd:", process.cwd());

    config.variables = JSON.parse(exports.replaceVariablesInCode(config.variables, JSON.stringify(config.variables)));

    function prepareAnchorCode (code) {

        if (/^\//.test(code)) {
            var path = code;

            if (/\.md$/.test(path)) {
                // TODO: Relocate this.

                code = FS.readFileSync(path, "utf8");

                code = exports.replaceVariablesInCode(config.variables, code);

                var tokens = MARKED.lexer(code);

                code = MARKED.parser(tokens, {
                    highlight: function (code, type) {
                        if (type) {
                            return HIGHLIGHT.highlight(type, code, true).value;
                        }
                        return HIGHLIGHT.highlightAuto(code).value;
                    }
                });
            } else {
                throw new Error("No parser found for file: " + path);
            }
        }

        if (code[".@"] === "github.com~0ink~codeblock/codeblock:Codeblock") {
            code = CODEBLOCK.run(code, {}, {
                sandbox: {
                    require: require
                }
            });

            code = exports.replaceVariablesInCode(config.variables, code);
        }

        return code;
    }

    var css = "";
    if (config.css) {
        css = config.css;
        if (css[".@"] === "github.com~0ink~codeblock/codeblock:Codeblock") {
            css = CODEBLOCK.thawFromJSON(css);
            if (css.getFormat() === "css") {
                css = css.getCode();                        
            }
        }
        if (/^\//.test(css)) {
            css = "./" + PATH.relative(sourceBasePath, css);
        }
    }

    if (config.scripts) {
        config.scripts = config.scripts.map(function (script) {
            if (/^\//.test(script)) {
                script = "./" + PATH.relative(sourceBasePath, script);
            }
            return script;
        });
    }

    if (
        config.anchors &&
        config.anchors.body
    ) {
        var targetPath = "index.html";
        var code = config.anchors.body || "";
        if (process.env.VERBOSE) console.log("body source", code);
        code = prepareAnchorCode(code);
        code = BOILERPLATE.wrapHTML(code, {
            css: css,
            scripts: config.scripts,
            uriDepth: uriDepth
        });
        if (process.env.VERBOSE) console.log("targetPath", process.cwd() + "/" + targetPath);
        FS.outputFileSync(targetPath, code, "utf8");
    }

    if (
        config &&
        config.files
    ) {
        Object.keys(config.files).forEach(function (targetSubpath) {
            if (/\.html?$/.test(targetSubpath)) {
                var code = FS.readFileSync(config.files[targetSubpath], "utf8");
                code = prepareAnchorCode(code);
                code = BOILERPLATE.wrapHTML(code, {
                    css: css,
                    scripts: config.scripts,
                    uriDepth: uriDepth + (targetSubpath.split("/").length - 1)
                });
                FS.outputFileSync(targetSubpath, code, "utf8");
            } else {
                FS.copySync(config.files[targetSubpath], targetSubpath);
            }
        });
    }
}

