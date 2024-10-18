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
  list.forEach(function (file) {
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
    console.log(`Function: ${func.name}, Line: ${func.line}, File: ${func.file}`);
  });
}
