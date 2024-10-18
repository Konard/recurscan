# recurscan

recurscan (recursion scan) is a CLI tool that scans JavaScript files for recursive functions and outputs their names, the line numbers, and the file paths where they are defined.

## Features

- Detects recursive functions in JavaScript files.
- Outputs the function names, line numbers, and file paths where the recursive functions are defined.
- Can scan individual files or all `.js` files in a folder.

## Installation

Install globally using Yarn:

```
yarn global add recurscan
```

## Usage

Run the tool to scan a file or folder:

```
recurscan <path>
```

- `<path>` can be a file path or a directory path.
- If a directory is passed, all `.js` files within the directory are scanned recursively.

## Example

To scan a file:

```
recurscan ./src/example.js
```

To scan a folder:

```
recurscan ./src
```

## License

This project is licensed under the Unlicense.
