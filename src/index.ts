#!/usr/bin/env node

import { Command } from "commander";
import { addCommand } from "./commands/add.js";
import { listCommand } from "./commands/list.js";
import { doneCommand } from "./commands/update.js";
import { deleteCommand } from "./commands/delete.js";
import { statsCommand } from "./commands/stats.js";
import { clearCommand } from "./commands/clear.js";

// Global error handlers to prevent crashes from unhandled exceptions
process.on("uncaughtException", (error: Error) => {
  console.error("\n❌ Unexpected error:", error.message);
  process.exit(1);
});

process.on("unhandledRejection", (reason: unknown) => {
  const message = reason instanceof Error ? reason.message : String(reason);
  console.error("\n❌ Unexpected error:", message);
  process.exit(1);
});

const program = new Command();

program
  .name("todo")
  .version("1.0.0")
  .description("A command-line Todo application");

// Add command: todo add <title>
program
  .command("add <title>")
  .description("Add a new todo")
  .action(async (title: string) => {
    try {
      if (!title || typeof title !== "string") {
        console.error("❌ Error: Title is required");
        console.log("\nUsage: todo add <title>");
        console.log('Example: todo add "Buy groceries"');
        process.exit(1);
      }
      await addCommand(title);
    } catch (error) {
      console.error(`❌ Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

// List command: todo list
program
  .command("list")
  .description("List all todos")
  .action(async () => {
    try {
      await listCommand();
    } catch (error) {
      console.error(`❌ Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

// Done command: todo done <id>
program
  .command("done <id>")
  .description("Mark a todo as completed")
  .action(async (id: string) => {
    try {
      if (!id || typeof id !== "string") {
        console.error("❌ Error: Todo ID is required");
        console.log("\nUsage: todo done <id>");
        console.log("Example: todo done abc123");
        process.exit(1);
      }
      await doneCommand(id);
    } catch (error) {
      console.error(`❌ Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

// Delete command: todo delete <id>
program
  .command("delete <id>")
  .description("Delete a todo")
  .action(async (id: string) => {
    try {
      if (!id || typeof id !== "string") {
        console.error("❌ Error: Todo ID is required");
        console.log("\nUsage: todo delete <id>");
        console.log("Example: todo delete abc123");
        process.exit(1);
      }
      await deleteCommand(id);
    } catch (error) {
      console.error(`❌ Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

// Stats command: todo stats [options]
program
  .command("stats")
  .description("Display todo statistics")
  .option("-j, --json", "Output stats as JSON")
  .action(async (options: { json?: boolean }) => {
    try {
      const jsonOutput = options.json ?? false;
      await statsCommand(jsonOutput);
    } catch (error) {
      const errMsg = (error as Error).message;
      // If the user requested JSON output, emit a machine-readable error object.
      if (options.json) {
        console.error(JSON.stringify({ error: "internal", message: errMsg }));
        process.exit(1);
      }
      console.error(`❌ Error: ${errMsg}`);
      process.exit(1);
    }
  });

// Clear command: todo clear
program
  .command("clear")
  .description("Clear all completed todos")
  .action(async () => {
    try {
      await clearCommand();
    } catch (error) {
      console.error(`❌ Error: ${(error as Error).message}`);
      process.exit(1);
    }
  });

program.parse();
