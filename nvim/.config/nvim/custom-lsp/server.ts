#!/usr/bin/env tsx

import {
  createConnection,
  TextDocuments,
  ProposedFeatures,
  InitializeParams,
  InitializeResult,
  TextDocumentSyncKind,
  CodeActionParams,
  CodeAction,
  CodeActionKind,
  ExecuteCommandParams,
  TextEdit,
} from 'vscode-languageserver/node';

import { TextDocument } from 'vscode-languageserver-textdocument';
import * as fs from 'fs';
import * as path from 'path';
import { isInsideIfStatement } from './ast-helpers';

const logFile = '/tmp/custom-lsp.log';

function log(message: string): void {
  const timestamp = new Date().toISOString();
  const logMessage = `${timestamp} - ${message}\n`;
  fs.appendFileSync(logFile, logMessage);
  console.error(`[Custom LSP] ${message}`);
}

const connection = createConnection(process.stdin, process.stdout);
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

connection.onInitialize((params: InitializeParams): InitializeResult => {
  log('LSP Server initializing...');
  log(`Client info: ${params.clientInfo?.name || 'unknown'}`);

  const result: InitializeResult = {
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Incremental,
      codeActionProvider: true,
      executeCommandProvider: {
        commands: ['custom.testAction', 'custom.showInfo']
      }
    }
  };

  return result;
});

connection.onInitialized(() => {
  log('LSP Server initialized successfully!');
});

connection.onCodeAction((params: CodeActionParams): CodeAction[] => {
  const document = documents.get(params.textDocument.uri);
  if (!document) {
    return [];
  }

  log(`Code action requested for ${params.textDocument.uri} at line ${params.range.start.line + 1}`);

  // Get the current line
  const line = document.getText({
    start: { line: params.range.start.line, character: 0 },
    end: { line: params.range.start.line + 1, character: 0 }
  });

  // Find the end of the line (before newline)
  const lineEndPos = line.length > 0 && line[line.length - 1] === '\n' ? line.length - 1 : line.length;

  const actions: CodeAction[] = [
    {
      title: '💬 Add Comment at End of Line',
      kind: CodeActionKind.QuickFix,
      edit: {
        changes: {
          [params.textDocument.uri]: [
            {
              range: {
                start: { line: params.range.start.line, character: lineEndPos },
                end: { line: params.range.start.line, character: lineEndPos }
              },
              newText: ' // TODO: Add comment here'
            }
          ]
        }
      }
    },
    {
      title: '🚀 Custom LSP: Test Action',
      kind: CodeActionKind.QuickFix,
      command: {
        title: 'Run Test Action',
        command: 'custom.testAction',
        arguments: [params.textDocument.uri, params.range.start.line]
      }
    },
    {
      title: '📊 Custom LSP: Show File Info',
      kind: CodeActionKind.RefactorExtract,
      command: {
        title: 'Show Info',
        command: 'custom.showInfo',
        arguments: [params.textDocument.uri]
      }
    }
  ];

  // Add context-aware action if inside an if statement
  if (isInsideIfStatement(document, params.range.start)) {
    actions.push({
      title: '🔄 Add else block',
      kind: CodeActionKind.RefactorRewrite,
      edit: {
        changes: {
          [params.textDocument.uri]: [
            {
              range: {
                start: { line: params.range.start.line + 1, character: 0 },
                end: { line: params.range.start.line + 1, character: 0 }
              },
              newText: '} else {\n  // TODO: handle else case\n'
            }
          ]
        }
      }
    });

    actions.push({
      title: '📝 Add console.log inside if',
      kind: CodeActionKind.QuickFix,
      edit: {
        changes: {
          [params.textDocument.uri]: [
            {
              range: {
                start: { line: params.range.start.line + 1, character: 0 },
                end: { line: params.range.start.line + 1, character: 0 }
              },
              newText: '  console.log("Inside if statement");\n'
            }
          ]
        }
      }
    });
  }

  return actions;
});

connection.onExecuteCommand((params: ExecuteCommandParams): void => {
  log(`Executing command: ${params.command} with args: ${JSON.stringify(params.arguments)}`);

  if (params.command === 'custom.testAction') {
    const [uri, line] = params.arguments || [];
    const message = `✅ Test action executed for ${path.basename(uri)} at line ${line + 1}`;

    connection.window.showInformationMessage(message);
    log(`ACTION EXECUTED: ${message}`);
  } else if (params.command === 'custom.showInfo') {
    const [uri] = params.arguments || [];
    const document = documents.get(uri);

    if (document) {
      const lineCount = document.lineCount;
      const text = document.getText();
      const charCount = text.length;
      const message = `📄 File: ${path.basename(uri)}\n` +
                      `Lines: ${lineCount}, Characters: ${charCount}`;

      connection.window.showInformationMessage(message);
      log(`INFO SHOWN: ${message}`);
    }
  }
});

documents.onDidChangeContent(change => {
  log(`Document changed: ${change.document.uri}`);
});

documents.onDidOpen(event => {
  log(`Document opened: ${event.document.uri}`);
});

documents.listen(connection);
connection.listen();

log('Custom TypeScript LSP Server started and listening...');