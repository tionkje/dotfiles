import { describe, it, expect } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { isInsideIfStatement } from './ast-helpers';

function createDocument(content: string): TextDocument {
  return TextDocument.create('file:///test.js', 'javascript', 1, content);
}

describe('isInsideIfStatement', () => {
  const testCode = `function test() {
  const value = 42;

  if (value > 40) {
    console.log("inside if");
  }

  console.log("outside if");

  if (value < 100) {
    const result = value * 2;
  } else {
    console.log("in else");
  }
}`;

  const document = createDocument(testCode);

  describe('should return true when cursor is', () => {
    it('inside if statement body', () => {
      // Line 4 (0-indexed): console.log("inside if");
      const position = { line: 4, character: 10 };
      expect(isInsideIfStatement(document, position)).toBe(true);
    });

    it('inside else statement body', () => {
      // Line 12 (0-indexed): console.log("in else");
      const position = { line: 12, character: 10 };
      expect(isInsideIfStatement(document, position)).toBe(true);
    });

    it('on the if keyword itself', () => {
      // Line 3 (0-indexed): if (value > 40) {
      const position = { line: 3, character: 2 }; // Position on 'if'
      expect(isInsideIfStatement(document, position)).toBe(true);
    });

    it('inside the condition parentheses', () => {
      // Line 3 (0-indexed): if (value > 40) {
      const position = { line: 3, character: 8 }; // Position on 'value' in condition
      expect(isInsideIfStatement(document, position)).toBe(true);
    });

    it('on the opening brace of if block', () => {
      // Line 3 (0-indexed): if (value > 40) {
      const position = { line: 3, character: 17 }; // Position on '{'
      expect(isInsideIfStatement(document, position)).toBe(true);
    });

    it('on the closing brace of if block', () => {
      // Line 5 (0-indexed): }
      const position = { line: 5, character: 2 }; // Position on '}'
      expect(isInsideIfStatement(document, position)).toBe(true);
    });
  });

  describe('should return false when cursor is', () => {
    it('outside any if statement', () => {
      // Line 7 (0-indexed): console.log("outside if");
      const position = { line: 7, character: 10 };
      expect(isInsideIfStatement(document, position)).toBe(false);
    });

    it('in the function but before any if', () => {
      // Line 1 (0-indexed): const value = 42;
      const position = { line: 1, character: 10 };
      expect(isInsideIfStatement(document, position)).toBe(false);
    });

    it('after all if statements', () => {
      // Line 14 (0-indexed): closing brace of function
      const position = { line: 14, character: 0 };
      expect(isInsideIfStatement(document, position)).toBe(false);
    });
  });

  describe('edge cases', () => {
    it('should handle nested if statements', () => {
      const nestedCode = `function test() {
  if (a) {
    if (b) {
      console.log("nested");
    }
  }
}`;
      const doc = createDocument(nestedCode);
      // Line 3 (0-indexed): console.log("nested");
      const position = { line: 3, character: 10 };
      expect(isInsideIfStatement(doc, position)).toBe(true);
    });

    it('should handle if-else-if chains', () => {
      const chainCode = `function test() {
  if (a) {
    console.log("a");
  } else if (b) {
    console.log("b");
  } else {
    console.log("else");
  }
}`;
      const doc = createDocument(chainCode);

      // Inside first if
      expect(isInsideIfStatement(doc, { line: 2, character: 10 })).toBe(true);

      // Inside else if - this might fail with current implementation
      expect(isInsideIfStatement(doc, { line: 4, character: 10 })).toBe(true);

      // Inside final else
      expect(isInsideIfStatement(doc, { line: 6, character: 10 })).toBe(true);
    });

    it('should handle ternary operators (not if statements)', () => {
      const ternaryCode = `const result = condition ? true : false;`;
      const doc = createDocument(ternaryCode);
      const position = { line: 0, character: 20 };
      expect(isInsideIfStatement(doc, position)).toBe(false);
    });
  });
});
