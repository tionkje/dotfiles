import * as ts from 'typescript';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { Range } from 'vscode-languageserver/node';

export function isInsideIfStatement(document: TextDocument, position: { line: number, character: number }): boolean {
  const text = document.getText();
  const offset = document.offsetAt(position);

  // Create a TypeScript source file
  const sourceFile = ts.createSourceFile(
    document.uri,
    text,
    ts.ScriptTarget.Latest,
    true
  );

  // Find the node at the cursor position
  function findNodeAtPosition(node: ts.Node): ts.Node | undefined {
    if (node.pos <= offset && offset <= node.end) {
      return ts.forEachChild(node, findNodeAtPosition) || node;
    }
    return undefined;
  }

  const nodeAtCursor = findNodeAtPosition(sourceFile);
  if (!nodeAtCursor) return false;

  // Walk up the AST to check if we're inside an if statement
  let currentNode: ts.Node | undefined = nodeAtCursor;
  while (currentNode) {
    if (ts.isIfStatement(currentNode)) {
      // Check if we're in the then branch or else branch
      const ifNode = currentNode as ts.IfStatement;
      if(ifNode.pos <= offset && offset <= ifNode.end) {
        return true;
      }
    }
    currentNode = currentNode.parent;
  }

  return false;
}

export interface IfStatementInfo {
  condition: string;
  conditionRange: Range;
  ifNode: ts.IfStatement;
  thenBranch: {
    text: string;
    range: Range;
  };
  elseBranch?: {
    text: string;
    range: Range;
  };
}

export function getIfStatementAtPosition(document: TextDocument, position: { line: number, character: number }): IfStatementInfo | null {
  const text = document.getText();
  const offset = document.offsetAt(position);

  const sourceFile = ts.createSourceFile(
    document.uri,
    text,
    ts.ScriptTarget.Latest,
    true
  );

  // Find the node at the cursor position
  function findNodeAtPosition(node: ts.Node): ts.Node | undefined {
    if (node.pos <= offset && offset <= node.end) {
      return ts.forEachChild(node, findNodeAtPosition) || node;
    }
    return undefined;
  }

  const nodeAtCursor = findNodeAtPosition(sourceFile);
  if (!nodeAtCursor) return null;

  // Walk up to find the if statement
  let currentNode: ts.Node | undefined = nodeAtCursor;
  while (currentNode) {
    if (ts.isIfStatement(currentNode)) {
      const ifNode = currentNode as ts.IfStatement;

      // Check if we're within the if statement
      if (ifNode.pos <= offset && offset <= ifNode.end) {
        // Extract the condition text
        const conditionStart = ifNode.expression.getStart(sourceFile);
        const conditionEnd = ifNode.expression.getEnd();
        const conditionText = text.substring(conditionStart, conditionEnd);

        // Calculate the condition range
        const conditionStartPos = document.positionAt(conditionStart);
        const conditionEndPos = document.positionAt(conditionEnd);

        // Extract then branch
        const thenStart = ifNode.thenStatement.getStart(sourceFile);
        const thenEnd = ifNode.thenStatement.getEnd();
        const thenText = text.substring(thenStart, thenEnd);
        const thenStartPos = document.positionAt(thenStart);
        const thenEndPos = document.positionAt(thenEnd);

        // Extract else branch if it exists
        let elseBranch = undefined;
        if (ifNode.elseStatement) {
          const elseStart = ifNode.elseStatement.getStart(sourceFile);
          const elseEnd = ifNode.elseStatement.getEnd();
          const elseText = text.substring(elseStart, elseEnd);
          const elseStartPos = document.positionAt(elseStart);
          const elseEndPos = document.positionAt(elseEnd);

          elseBranch = {
            text: elseText,
            range: {
              start: elseStartPos,
              end: elseEndPos
            }
          };
        }

        return {
          condition: conditionText,
          conditionRange: {
            start: conditionStartPos,
            end: conditionEndPos
          },
          ifNode,
          thenBranch: {
            text: thenText,
            range: {
              start: thenStartPos,
              end: thenEndPos
            }
          },
          elseBranch
        };
      }
    }
    currentNode = currentNode.parent;
  }

  return null;
}

export function invertCondition(condition: string): string {
  // Parse the condition as an expression
  const sourceFile = ts.createSourceFile(
    'temp.ts',
    condition,
    ts.ScriptTarget.Latest,
    true
  );

  const statement = sourceFile.statements[0];
  if (!statement || !ts.isExpressionStatement(statement)) {
    // If it's not a statement, try parsing as expression
    return invertExpression(condition);
  }

  return invertExpression(condition);
}

function invertExpression(expr: string): string {
  const trimmed = expr.trim();

  // Handle negation operator
  if (trimmed.startsWith('!')) {
    // Remove the negation
    return trimmed.substring(1).trim();
  }

  // Handle parenthesized expressions - but check for operators inside
  if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
    const inner = trimmed.substring(1, trimmed.length - 1).trim();
    // If it's a simple expression in parens, just invert it
    const innerInverted = invertExpression(inner);
    // Only add extra parens if needed
    if (innerInverted.includes(' ') && !innerInverted.startsWith('!(')) {
      return `!(${inner})`;
    }
    return innerInverted;
  }

  // Handle && and || BEFORE comparison operators (higher precedence in parsing)
  // First check for OR (lower precedence)
  const orIndex = findOperatorIndex(trimmed, '||');
  if (orIndex !== -1) {
    // Split at the OR, being careful about nested expressions
    const left = trimmed.substring(0, orIndex).trim();
    const right = trimmed.substring(orIndex + 2).trim();
    // De Morgan's law: !(A || B) = !A && !B
    return `${invertExpression(left)} && ${invertExpression(right)}`;
  }

  // Then check for AND
  const andIndex = findOperatorIndex(trimmed, '&&');
  if (andIndex !== -1) {
    const left = trimmed.substring(0, andIndex).trim();
    const right = trimmed.substring(andIndex + 2).trim();
    // De Morgan's law: !(A && B) = !A || !B
    return `${invertExpression(left)} || ${invertExpression(right)}`;
  }

  // Handle comparison operators
  const comparisons: [RegExp, string][] = [
    [/^(.+?)===(.+)$/, '$1!==$2'],
    [/^(.+?)!==(.+)$/, '$1===$2'],
    [/^(.+?)==(.+)$/, '$1!=$2'],
    [/^(.+?)!=(.+)$/, '$1==$2'],
    [/^(.+?)>=(.+)$/, '$1<$2'],
    [/^(.+?)<=(.+)$/, '$1>$2'],
    [/^(.+?)>(.+)$/, '$1<=$2'],
    [/^(.+?)<(.+)$/, '$1>=$2'],
  ];

  for (const [pattern, replacement] of comparisons) {
    const match = trimmed.match(pattern);
    if (match) {
      return trimmed.replace(pattern, replacement);
    }
  }

  // For everything else, just add negation
  return `!(${trimmed})`;
}

// Helper to find operator index, skipping nested parentheses
function findOperatorIndex(str: string, operator: string): number {
  let depth = 0;
  for (let i = 0; i < str.length - operator.length + 1; i++) {
    if (str[i] === '(') depth++;
    if (str[i] === ')') depth--;
    if (depth === 0 && str.substring(i, i + operator.length) === operator) {
      return i;
    }
  }
  return -1;
}
