#!/bin/bash

# # Define project name
# PROJECT_NAME="recurscan"

# # Create project directory
# mkdir $PROJECT_NAME
# cd $PROJECT_NAME

# Create directories
mkdir -p bin src test

# Create main CLI tool script
cat <<EOL > bin/recurscan.js
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const parser = require('@babel/parser');
const traverse = require('@babel/traverse').default;

const args = process.argv.slice(2);
if (args.length === 0) {
    console.error('Usage: node recurscan.js <path>');
    process.exit(1);
}

const targetPath = args[0];
const recursiveFunctions = [];

function getJsFiles(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.resolve(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(getJsFiles(file));
        } else if (file.endsWith('.js')) {
            results.push(file);
        }
    });
    return results;
}

function processFile(filePath) {
    const code = fs.readFileSync(filePath, 'utf8');
    const ast = parser.parse(code, {
        sourceType: 'module',
        plugins: ['jsx', 'typescript'],
        sourceFilename: filePath,
        tokens: true,
        ranges: true,
        errorRecovery: true,
    });

    traverse(ast, {
        FunctionDeclaration(path) {
            const funcName = path.node.id.name;
            const startLine = path.node.loc.start.line;

            let isRecursive = false;

            path.traverse({
                CallExpression(innerPath) {
                    const callee = innerPath.node.callee;
                    if (callee.type === 'Identifier' && callee.name === funcName) {
                        isRecursive = true;
                    }
                }
            });

            if (isRecursive) {
                recursiveFunctions.push({
                    name: funcName,
                    line: startLine,
                    file: filePath
                });
            }
        },

        FunctionExpression(path) {
            const funcName = path.node.id ? path.node.id.name : null;
            const startLine = path.node.loc.start.line;

            let variableName = null;

            if (path.parent.type === 'VariableDeclarator' && path.parent.init === path.node) {
                variableName = path.parent.id.name;
            } else if (path.parent.type === 'AssignmentExpression' && path.parent.right === path.node) {
                if (path.parent.left.type === 'Identifier') {
                    variableName = path.parent.left.name;
                }
            }

            const nameToCheck = funcName || variableName;

            if (nameToCheck) {
                let isRecursive = false;

                path.traverse({
                    CallExpression(innerPath) {
                        const callee = innerPath.node.callee;
                        if (callee.type === 'Identifier' && callee.name === nameToCheck) {
                            isRecursive = true;
                        }
                    }
                });

                if (isRecursive) {
                    recursiveFunctions.push({
                        name: nameToCheck,
                        line: startLine,
                        file: filePath
                    });
                }
            }
        },

        ArrowFunctionExpression(path) {
            const startLine = path.node.loc.start.line;

            let variableName = null;

            if (path.parent.type === 'VariableDeclarator' && path.parent.init === path.node) {
                variableName = path.parent.id.name;
            } else if (path.parent.type === 'AssignmentExpression' && path.parent.right === path.node) {
                if (path.parent.left.type === 'Identifier') {
                    variableName = path.parent.left.name;
                }
            }

            if (variableName) {
                let isRecursive = false;

                path.traverse({
                    CallExpression(innerPath) {
                        const callee = innerPath.node.callee;
                        if (callee.type === 'Identifier' && callee.name === variableName) {
                            isRecursive = true;
                        }
                    }
                });

                if (isRecursive) {
                    recursiveFunctions.push({
                        name: variableName,
                        line: startLine,
                        file: filePath
                    });
                }
            }
        }
    });
}

function processPath(targetPath) {
    const stat = fs.statSync(targetPath);
    if (stat.isFile()) {
        if (targetPath.endsWith('.js')) {
            processFile(path.resolve(targetPath));
        }
    } else if (stat.isDirectory()) {
        const jsFiles = getJsFiles(targetPath);
        jsFiles.forEach(file => {
            processFile(file);
        });
    } else {
        console.error('Invalid path');
        process.exit(1);
    }
}

processPath(targetPath);

if (recursiveFunctions.length === 0) {
    console.log('No recursive functions found.');
} else {
    console.log('Recursive functions found:');
    recursiveFunctions.forEach(func => {
        console.log(\`Function: \${func.name}, Line: \${func.line}, File: \${func.file}\`);
    });
}
EOL

# Create src/utils.js (optional for future use)
cat <<EOL > src/utils.js
// Utility functions can be added here for future extension
EOL

# Create a test file in the test directory (optional)
cat <<EOL > test/example-test.js
// Example test cases can be added here in the future
EOL

# Create README.md
cat <<EOL > README.md
# Recurscan

Recurscan is a CLI tool that scans JavaScript files for recursive functions and outputs their names, the line numbers, and the file paths where they are defined.

## Features

- Detects recursive functions in JavaScript files.
- Outputs the function names, line numbers, and file paths where the recursive functions are defined.
- Can scan individual files or all \`.js\` files in a folder.

## Installation

Install globally using Yarn:

\`\`\`
yarn global add recurscan
\`\`\`

## Usage

Run the tool to scan a file or folder:

\`\`\`
recurscan <path>
\`\`\`

- \`<path>\` can be a file path or a directory path.
- If a directory is passed, all \`.js\` files within the directory are scanned recursively.

## Example

To scan a file:

\`\`\`
recurscan ./src/example.js
\`\`\`

To scan a folder:

\`\`\`
recurscan ./src
\`\`\`

## License

This project is licensed under the Unlicense.
EOL

# Create package.json
cat <<EOL > package.json
{
  "name": "recurscan",
  "version": "1.0.0",
  "description": "A CLI tool to detect recursive functions in JavaScript files.",
  "main": "bin/recurscan.js",
  "bin": {
    "recurscan": "./bin/recurscan.js"
  },
  "scripts": {
    "start": "node bin/recurscan.js"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/konard/recurscan.git"
  },
  "keywords": [
    "recursive",
    "functions",
    "javascript",
    "cli",
    "babel",
    "traverse"
  ],
  "author": "konard",
  "license": "Unlicense",
  "dependencies": {
    "@babel/parser": "^7.21.0",
    "@babel/traverse": "^7.21.0"
  }
}
EOL

echo "Repository initialized successfully!"

# This file was generated with help of GPT-o1 and GPT-4o, also edited manually