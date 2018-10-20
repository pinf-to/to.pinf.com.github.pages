


const LIB = require("bash.origin.lib").forPackage(__dirname).LIB;


const PATH = LIB.PATH;
const FS = LIB.FS_EXTRA;
const LODASH = LIB.LODASH
const CODEBLOCK = LIB.CODEBLOCK;
const ESCAPE_REGEXP = LIB.ESCAPE_REGEXP;

const MARKED = LIB.MARKED;
const HIGHLIGHT = LIB.HIGHLIGHT_JS;

const VERBOSE = !!process.env.VERBOSE;


exports.forConfig = function (config) {
    return exports;
}


exports.replaceVariablesInCode = function (variables, code) {

    //console.log("replaceVariablesInCode(variables, code)", variables, code);

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

                if (VERBOSE) console.log("replace", match[0], variables[match[1]]);

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

    if (config.variables) {
        config.variables = JSON.parse(exports.replaceVariablesInCode(config.variables, JSON.stringify(config.variables)));
    }

    function prepareAnchorCode (code) {

        if (/^\//.test(code)) {
            var path = code;

            if (/\.md$/.test(path)) {
                // TODO: Relocate this.

                code = FS.readFileSync(path, "utf8");

                code = exports.replaceVariablesInCode(config.variables, code);

                code = code.replace(/(<!--ON_RUN>>>|<<<ON_RUN-->)/g, "");

                var blocks = {
                    result: []
                };

                var lines = code.split("\n");
                var buffer = null;
                var re = /^RESULT:(.+)$/;
                lines = lines.map(function (line) {

                    if (
                        !buffer ||
                        typeof buffer === "string"
                    ) {
                        if (/```/.test(line)) {
                            buffer = [];
                        }
                    } else
                    if (
                        buffer &&
                        typeof buffer !== "string"
                    ) {
                        if (/```/.test(line)) {
                            buffer = buffer.join("\n");
                        } else {
                            buffer.push(line);
                        }
                    }
                    var match = re.exec(line);
                    if (match) {
                        blocks.result.push(
                            match[1].replace(/&CODE&/g, buffer)
                        );
                        line = line.replace(
                            new RegExp(ESCAPE_REGEXP(match[0]), "g"),
                            '---ReSuLt-BlOcK-' + (blocks.result.length - 1) + '---'
                        );
                    }

                    return line;
                });

                code = lines.join("\n");

                var tokens = MARKED.lexer(code);

                code = MARKED.parser(tokens, {
                    highlight: function (code, type) {
                        if (type) {
                            return HIGHLIGHT.highlight(type, code, true).value;
                        }
                        return HIGHLIGHT.highlightAuto(code).value;
                    }
                });

                re = /<p>---ReSuLt-BlOcK-(\d+)---<\/p>/gm;
                while ( (match = re.exec(code)) ) {
                    code = code.replace(
                        new RegExp(ESCAPE_REGEXP(match[0]), "g"),
                        [
                            '<div class="markdown-block-result">',
                            '<div class="result-label">Result</div>',
                            blocks.result[parseInt(match[1])],
                            '</div>'
                        ].join("")
                    );
                }

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
            } else
            if (css.getFormat() === "javascript") {
                css = CODEBLOCK.run(css, {
                    config: config
                }, {
                    sandbox: {
                        require: require,
                        process: process
                    }
                });
            }
        }
        if (/^\//.test(css)) {
            css = "./" + PATH.relative(sourceBasePath, css);
        }
    }
    if (process.env.VERBOSE) console.log("css", css);

    if (config.scripts) {
        config.scripts = config.scripts.map(function (script) {
            if (/^\//.test(script)) {
                script = "./" + PATH.relative(sourceBasePath, script);
            }
            return script;
        });
    }
    if (process.env.VERBOSE) console.log("config.scripts", config.scripts);

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
        if (VERBOSE) console.log("code:", code);
        FS.outputFileSync(targetPath, code, "utf8");
    }

    if (
        config &&
        config.files
    ) {
        var files = config.files;

        if (files[".@"] === "github.com~0ink~codeblock/codeblock:Codeblock") {
            files = CODEBLOCK.thawFromJSON(files);
            if (files.getFormat() === "javascript") {
                files = CODEBLOCK.run(files, {
                    config: config
                }, {
                    sandbox: {
                        require: require,
                        process: process
                    }
                });
            }
        }

        if (VERBOSE) console.log("files:", files);

        Object.keys(files).forEach(function (targetSubpath) {

            if (!Array.isArray(targetSubpath)) {
                targetSubpath = [
                    targetSubpath
                ];
            }

            targetSubpath.forEach(function (targetSubpath) {

                var filePath = files[targetSubpath];

                if (/\.html?$/.test(targetSubpath)) {
                    var code = FS.readFileSync(filePath, "utf8");
                    code = prepareAnchorCode(code);
                    code = BOILERPLATE.wrapHTML(code, {
                        css: css,
                        scripts: config.scripts,
                        uriDepth: uriDepth + (targetSubpath.split("/").length - 1)
                    });
                    FS.outputFileSync(targetSubpath, code, "utf8");
                } else {

                    var targetPath = targetSubpath.replace(/(^\/|\/\*$)/g, "");
                    
                    if (VERBOSE) console.log("Copy:", filePath, targetPath, "(pwd: " + process.cwd() + ")");

                    FS.copySync(filePath, targetPath);
                }
            });
        });
    }


    if (config.routes) {
        if (process.env.VERBOSE) console.log("config.routes", config.routes);

        // Will publish all resources set to `print: true`.
        LIB.BASH_ORIGIN_EXPRESS.hookRoutes(config.routes);
    }
}
