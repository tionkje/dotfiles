import * as ts from 'typescript';
import { TextDocument } from 'vscode-languageserver-textdocument';

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
